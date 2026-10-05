cd /d "%~dp0"
call killp.bat emacs
powershell doom.ps1 sync
echo start emacs server...
call emacs_server.bat
echo ensuring server is running...
timeout /t 10 /nobreak >nul

call emacs_client.bat
echo DONE