@echo off
emacsclientw.exe --alternate-editor="" -n -c %*
exit /b %errorlevel%