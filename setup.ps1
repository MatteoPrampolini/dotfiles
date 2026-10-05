# Read the README first.
# This script changes your actual config paths and may perform non-reversible
# operations. Know what you're doing before using --for-real.

$isAdmin = (
    [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin){
    Write-Host "Run this as administrator."
    exit 1
}

$DryRun = $true

function Show-Help {
    Write-Host @"
Usage:
  .\setup.ps1 [options]

Options:
  --for-real    Actually create the symlinks.
                Without this flag you are running a dry-run.
  -h, --help    Show this help.
"@
}

foreach ($arg in $args) {
    switch ($arg) {
        "--for-real" {
            $DryRun = $false
        }

        "-h" {
            Show-Help
            exit 0
        }

        "--help" {
            Show-Help
            exit 0
        }

        default {
            Write-Error "Unknown option: $arg"
            Show-Help
            exit 1
        }
    }
}

$dotfiles = "$HOME\dotfiles"

$links = @(
    @{
        Path   = "$HOME\.doom.d"
        Target = "$dotfiles\doom"
    },
    @{
        Path   = "$HOME\.glzr"
        Target = "$dotfiles\glazeWM"
    }
)

if ($DryRun) {
    Write-Host "DRY RUN - nothing will be changed."
    Write-Host "Use --for-real to actually create the symlinks."
    Write-Host
}

foreach ($link in $links) {
    $path = $link.Path
    $target = $link.Target

    if (-not (Test-Path $target)) {
        Write-Error "Target does not exist: $target"
        continue
    }

    if ($DryRun) {
        if (Test-Path $path) {
            Write-Host "REMOVE $path"
        }

        Write-Host "LINK   $path"
        Write-Host "    -> $target"
        Write-Host
        continue
    }

    if (Test-Path $path) {
        $answer = Read-Host "'$path' already exists and will be removed. Continue? [y/N]"

        if ($answer -notmatch '^[Yy]$') {
            Write-Host "SKIP   $path"
            Write-Host
            continue
        }

        Remove-Item $path -Recurse -Force
    }

    Write-Host "LINK   $path"
    Write-Host "    -> $target"

    New-Item `
        -ItemType SymbolicLink `
        -Path $path `
        -Target $target | Out-Null

    Write-Host
}
