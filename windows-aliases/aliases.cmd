@echo off
doskey doom=powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\.emacs.d\bin\doom.ps1" $*

doskey killp=call "%USERPROFILE%\cmd\killp.bat" $*

doskey emacsc=call "%USERPROFILE%\cmd\emacs_client.bat" $*
doskey emacss=call "%USERPROFILE%\cmd\emacs_server.bat" $*
doskey emacsu=call "%USERPROFILE%\cmd\emacsu.bat" $*