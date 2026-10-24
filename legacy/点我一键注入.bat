@echo off
setlocal
title Fujiang Armor Installer
echo.
echo Installing Fujiang Armor...
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set "DSH_INSTALL_RESULT=%ERRORLEVEL%"
echo.
if not "%DSH_INSTALL_RESULT%"=="0" echo Installation failed. See the message above.
if not "%DSH_INSTALL_NO_PAUSE%"=="1" pause
exit /b %DSH_INSTALL_RESULT%
