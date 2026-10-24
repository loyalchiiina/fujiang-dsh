@echo off
chcp 936 >nul 2>&1
setlocal enabledelayedexpansion
title 富江破甲 fujiang-armor - 一键安装

cd /d "%~dp0"

echo ==================================================
echo   富江破甲 fujiang-armor  一键安装
echo   自动装到 web 端 + 桌面端
echo ==================================================
echo.

if not exist "%~dp0install.ps1" (
  echo [失败] 找不到 install.ps1
  echo        请确认本 .bat 与 install.ps1 在同一个文件夹里
  echo        如果你是从 zip 里直接双击的，请先完整解压出来再运行
  echo.
  pause
  exit /b 1
)

where powershell >nul 2>&1
if errorlevel 1 (
  echo [失败] 找不到 powershell
  pause
  exit /b 1
)

echo 正在安装，请稍候（约 5-15 秒）...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
set RC=%ERRORLEVEL%

echo.
if "%RC%"=="0" (
  echo ==================================================
  echo   安装完成
  echo ==================================================
  echo.
  echo 最后一步：完全重启 DSH 才会生效
  echo   桌面端：关闭窗口 - 右键托盘图标退出 - 重新打开
  echo   web 端：关掉那个命令行窗口 - 重新启动
  echo.
  echo ------------------------------------------------
  echo   重启后怎么用（重要，顺序别搞反）
  echo ------------------------------------------------
  echo   1. 对话用 DSH 标准模式，不要用自定义预设
  echo      （自定义预设会自带人格，把破甲压掉）
  echo   2. 先用官方 API 发一句话，确认已经破甲
  echo      （输入「富江」，看是否显示富江破甲已激活）
  echo   3. 确认破甲成功后，再切到免费额度通道
  echo.
  echo   一句话：标准模式 - 官方API发一句 - 确认破甲 - 切免费额度
  echo   详见 README.md 的「安装后必读：正确使用方法」
) else (
  echo ==================================================
  echo   安装失败（错误码 %RC%）
  echo ==================================================
  echo.
  echo 请把上面从 [FAIL] 开始的几行截图发出来。
  echo 常见原因：
  echo   1. 没装 DSH，或 DSH 从未启动过（找不到 .dsh 目录）
  echo   2. zip 没解压就双击运行
)

echo.
pause
endlocal
