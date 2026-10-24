@echo off
setlocal
title Fujiang Armor Uninstaller
echo.
echo Uninstalling Fujiang Armor...
if exist "%~dp0uninstall.ps1" goto run
echo ERROR: uninstall.ps1 was not found next to this launcher.
set "DSH_UNINSTALL_RESULT=2"
goto finished

:run
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
set "DSH_UNINSTALL_RESULT=%ERRORLEVEL%"

:finished
echo.
if not "%DSH_UNINSTALL_RESULT%"=="0" echo Uninstall failed. See the message above.
if not "%DSH_UNINSTALL_NO_PAUSE%"=="1" pause
exit /b %DSH_UNINSTALL_RESULT%
