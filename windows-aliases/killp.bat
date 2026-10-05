@echo off
if "%~1"=="" (
    echo Uso: killp nomeprocesso
    exit /b 1
)

set "KILLP_NAME=%~1"

powershell -NoProfile -Command "$name=$env:KILLP_NAME; $p=Get-Process | Where-Object { $_.ProcessName -like \"*$name*\" }; if (-not $p) { Write-Host \"Nessun processo trovato per: $name\"; exit 1 }; $p | ForEach-Object { Write-Host \"Killing $($_.ProcessName) PID $($_.Id)\" }; $p | Stop-Process -Force"
