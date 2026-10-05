#THIS SHIT IS 100% VIBECODED AND REQUIRES TO RUN AS ADMIN.
# we ball it.
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# Fixed locations under the current user's home directory.
$aliasesFile = "$HOME\dotfiles\windows-aliases\aliases.cmd"
$registryPath = 'HKCU:\Software\Microsoft\Command Processor'

# Validate required files before changing anything.
if (-not (Test-Path -LiteralPath $aliasesFile -PathType Leaf)) {
    throw "Aliases file not found: $aliasesFile"
}

$emacsClient = (
    Get-Command emacsclientw.exe -CommandType Application -ErrorAction Stop |
        Select-Object -First 1
).Source

# Identify the current Windows user.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$userSid = $identity.User.Value
$userName = $identity.Name

$defaultTaskName = "Emacs Daemon - $env:USERNAME"
$allTasks = @(Get-ScheduledTask)

# Find existing Emacs startup tasks belonging to this user.
$matchingTasks = @(
    foreach ($candidate in $allTasks) {
        $owner = $candidate.Principal.UserId

        if ($owner -ne $userSid -and $owner -ne $userName) {
            try {
                $account = [Security.Principal.NTAccount]::new($owner)
                $ownerSid = $account.Translate(
                    [Security.Principal.SecurityIdentifier]
                ).Value
            }
            catch {
                continue
            }

            if ($ownerSid -ne $userSid) {
                continue
            }
        }

        $matches = (
            $candidate.TaskName -eq $defaultTaskName -and
            $candidate.TaskPath -eq '\'
        )

        foreach ($candidateAction in $candidate.Actions) {
            $command = "$($candidateAction.Execute) $($candidateAction.Arguments)"

            $usesServerScript = $command -match (
                '(?i)(^|[\\/"\s])(emacss(?:\.(?:bat|cmd))?|emacs_server\.bat)(?=["\s]|$)'
            )

            $startsDaemon = (
                $command -match '(?i)(?:runemacs|emacs)\.exe' -and
                $command -match '--(?:bg-|fg-)?daemon'
            )

            $usesClientBootstrap = (
                $command -match '(?i)emacsclientw?\.exe' -and
                $command -match '--alternate-editor=' -and
                $command -match '--eval\s+"?t"?(?:\s|$)'
            )

            if ($usesServerScript -or $startsDaemon -or $usesClientBootstrap) {
                $matches = $true
            }
        }

        if ($matches) {
            $candidate
        }
    }
)

if ($matchingTasks.Count -gt 1) {
    $names = ($matchingTasks | ForEach-Object {
        "$($_.TaskPath)$($_.TaskName)"
    }) -join ', '

    throw "Multiple Emacs startup tasks found: $names. Remove the duplicate startup tasks and run this script again."
}

if ($matchingTasks.Count -eq 1) {
    $taskName = $matchingTasks[0].TaskName
    $taskPath = $matchingTasks[0].TaskPath
}
else {
    $taskName = $defaultTaskName
    $taskPath = '\'

    $nameConflict = @($allTasks | Where-Object {
        $_.TaskName -eq $taskName -and $_.TaskPath -eq $taskPath
    })

    if ($nameConflict.Count -gt 0) {
        throw "Task $taskPath$taskName already belongs to another user."
    }
}

# Start or reuse the daemon without opening an Emacs frame.
$action = New-ScheduledTaskAction `
    -Execute $emacsClient `
    -Argument '--alternate-editor="" --quiet --suppress-output --eval "t"' `
    -WorkingDirectory $HOME

# Run at logon, under the current user's interactive session.
$trigger = New-ScheduledTaskTrigger `
    -AtLogOn `
    -User $userSid

$principal = New-ScheduledTaskPrincipal `
    -UserId $userSid `
    -LogonType Interactive `
    -RunLevel Limited

# Allow battery operation and ignore overlapping task executions.
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

$taskDefinition = New-ScheduledTask `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description 'Start or reuse the Emacs daemon at logon without opening a window.'

# Create the task or replace its existing configuration.
Register-ScheduledTask `
    -TaskName $taskName `
    -TaskPath $taskPath `
    -InputObject $taskDefinition `
    -Force | Out-Null

Write-Host "Task configured: $taskPath$taskName"

# Create or update CMD AutoRun for the current user.
if (-not (Test-Path -LiteralPath $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

$autoRun = '"' + $aliasesFile + '"'

New-ItemProperty `
    -Path $registryPath `
    -Name AutoRun `
    -Value $autoRun `
    -PropertyType String `
    -Force | Out-Null

Write-Host "AutoRun configured: $autoRun"
Write-Host "Emacs client: $emacsClient"
Write-Host "User: $userName"
Write-Host 'Done. Open a new CMD window to load the aliases.'
Write-Host 'The Emacs daemon will start at your next logon.'
