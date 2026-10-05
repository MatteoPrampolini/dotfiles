@echo off
emacsclient.exe --alternate-editor="" --eval "t"
exit /b %errorlevel%