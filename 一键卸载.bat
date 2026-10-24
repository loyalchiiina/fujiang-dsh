@echo off
chcp 936 >nul 2>&1
setlocal enabledelayedexpansion
title 富江破甲 fujiang-armor - 一键卸载

cd /d "%~dp0"

echo ==================================================
echo   富江破甲 fujiang-armor  一键卸载
echo   从 web 端 + 桌面端摘除
echo ==================================================
echo.

if not exist "%~dp0uninstall.ps1" (
  echo [失败] 找不到 uninstall.ps1
  echo        请确认本 .bat 与 uninstall.ps1 在同一个文件夹里
  pause
  exit /b 1
)

where powershell >nul 2>&1
if errorlevel 1 (
  echo [失败] 找不到 powershell
  pause
  exit /b 1
)

echo 正在卸载，请稍候...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
set RC=%ERRORLEVEL%

echo.
if "%RC%"=="0" (
  echo ==================================================
  echo   卸载完成
  echo ==================================================
  echo.
  echo 完全重启 DSH 后彻底生效。
  echo.
  echo 注意：插件文件本身保留在 .dsh\local-plugins\fujiang-armor，
  echo       只是不再被加载。想彻底删除请手动删该目录。
) else (
  echo ==================================================
  echo   卸载过程有异常（错误码 %RC%）
  echo ==================================================
  echo.
  echo 请把上面的输出截图发出来。
)

echo.
pause
endlocal
