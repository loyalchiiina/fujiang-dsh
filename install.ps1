<#
.SYNOPSIS
  富江破甲 (fujiang-armor) 通用安装器 —— 适配任意 DSH 安装路径 / 任意盘符 / web 与客户端双端。
.DESCRIPTION
  零联网、零依赖下载：插件所需的内核 API 包已随包附带（plugin\node_modules）。
  自动探测 DSH_HOME、node 运行时、目标 profile，执行「落盘 → 挂载 → 声明 → 校验」四步。
.PARAMETER Profile
  目标 profile 名，可多选：web / desktop / xiufu ...；填 all 表示全部已存在的 profile。
.PARAMETER DshHome
  手动指定 DSH 数据根目录（默认 %USERPROFILE%\.dsh，可用环境变量 DSH_HOME 覆盖）。
.PARAMETER NodeExe
  手动指定 node.exe 路径（默认自动探测 DSH 运行时，其次 PATH）。
.PARAMETER PluginDir
  插件落盘目录（默认 <DshHome>\local-plugins\fujiang-armor）。
.PARAMETER Force
  已存在时强制覆盖插件目录（会先备份旧目录）。
.PARAMETER WhatIf
  只打印计划，不落盘。
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install.ps1
  powershell -ExecutionPolicy Bypass -File install.ps1 -Profile web,desktop
  powershell -ExecutionPolicy Bypass -File install.ps1 -Profile all -Force
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string[]]$Profile = @(),
  [string]$DshHome,
  [string]$NodeExe,
  [string]$PluginDir,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$PluginName  = 'fujiang-armor'
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
# 两种布局自适应：
#   ① Release ZIP 布局：<root>\plugin\  （含内置 node_modules，零联网）
#   ② Git 仓库/源码布局：插件文件直接在 <root>\  （node_modules 需自备，见 README）
$SrcPlugin = Join-Path $PackageRoot 'plugin'
if (-not (Test-Path (Join-Path $SrcPlugin 'index.js'))) { $SrcPlugin = $PackageRoot }
$Stamp       = Get-Date -Format 'yyyyMMdd-HHmmss'

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }
function Step($n, $msg) { Write-Host ""; Write-Host "[$n] $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "    [OK]   $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "    [WARN] $msg" -ForegroundColor Yellow }
function Die($msg)  { Write-Host "    [FAIL] $msg" -ForegroundColor Red; exit 1 }

# 原生命令封装：stderr 不触发 NativeCommandError（$ErrorActionPreference='Stop' 下的坑）
function Invoke-Native {
  # 注意：参数名不能用 $Args —— 它是 PowerShell 自动变量（大小写不敏感），会被覆盖成空。
  param([string]$Exe, [string[]]$ArgList)
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $out = & $Exe @ArgList 2>&1 | ForEach-Object { "$_" } | Out-String
    $code = $LASTEXITCODE
    return [pscustomobject]@{ Output = $out; ExitCode = $code }
  } finally {
    $ErrorActionPreference = $prev
  }
}

Say "==================================================" DarkCyan
Say "  富江破甲 fujiang-armor  通用安装器  v0.4.5" DarkCyan
Say "  适配 DSH 0.2.x 内核 / web 端 + 客户端双端" DarkCyan
Say "==================================================" DarkCyan

# ---------------------------------------------------------------- 0 包体自检
Step 0 '安装包完整性自检'
foreach ($f in @('index.js','client.js','package.json','cordis.patch.yml','cordis.override.patch.yml','prompts','locale')) {
  if (-not (Test-Path (Join-Path $SrcPlugin $f))) { Die "安装包不完整，缺少 $f —— 请重新解压完整压缩包" }
}
# 离线依赖只随 Release ZIP 分发（6.3 MB / 877 文件），Git 源码仓库不含。
if (-not (Test-Path (Join-Path $SrcPlugin 'node_modules'))) {
  Die @"
源码布局缺少 node_modules（离线依赖闭包）。
   本仓库是 Git 源码，不携带 node_modules。
   请到 Releases 页面下载 fujiang-armor-universal-0.4.5-*.zip 安装包，解压后运行其中的一键安装.bat。
   下载地址：https://github.com/loyalchiiina/fujiang-dsh/releases
"@
}
$pkgJson = Get-Content (Join-Path $SrcPlugin 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Ok "插件 $($pkgJson.name) v$($pkgJson.version)，离线依赖已内置"

# ---------------------------------------------------------------- 1 定位 DSH_HOME
Step 1 '定位 DSH 数据根目录'
if (-not $DshHome) {
  if ($env:DSH_HOME -and (Test-Path $env:DSH_HOME)) { $DshHome = $env:DSH_HOME }
  elseif (Test-Path (Join-Path $env:USERPROFILE '.dsh')) { $DshHome = Join-Path $env:USERPROFILE '.dsh' }
}
if (-not $DshHome -or -not (Test-Path $DshHome)) { Die "找不到 DSH 数据目录。请用 -DshHome 指定（通常是 %USERPROFILE%\.dsh）" }
$DshHome = (Resolve-Path $DshHome).Path
Ok "DSH_HOME = $DshHome"

$ProfilesRoot = Join-Path $DshHome 'profiles'
if (-not (Test-Path $ProfilesRoot)) { Die "找不到 profiles 目录：$ProfilesRoot（DSH 未初始化？请先启动一次 DSH）" }

# ---------------------------------------------------------------- 2 定位 node.exe
Step 2 '定位 Node 运行时'
$nodeCandidates = @()
if ($NodeExe) { $nodeCandidates += $NodeExe }
$rtRoot = Join-Path $DshHome 'dsh-runtimes'
if (Test-Path $rtRoot) {
  $nodeCandidates += (Get-ChildItem $rtRoot -Directory -EA SilentlyContinue |
    ForEach-Object { Join-Path $_.FullName 'dependencies\node\bin\node.exe' } |
    Where-Object { Test-Path $_ })
}
$nodeCandidates += (Get-Command node -EA SilentlyContinue | ForEach-Object { $_.Source })
$nodeCandidates += @(
  "$env:ProgramFiles\nodejs\node.exe",
  "$env:LOCALAPPDATA\Programs\nodejs\node.exe"
)
$NodeExe = $nodeCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $NodeExe) { Die "找不到 node.exe。请用 -NodeExe 指定（DSH 自带运行时在 <DSH_HOME>\dsh-runtimes\*\dependencies\node\bin\node.exe）" }
$nodeVer = (& $NodeExe -v) 2>$null
Ok "node = $NodeExe ($nodeVer)"

# ---------------------------------------------------------------- 3 选定 profile
Step 3 '选定目标 profile'
$allProfiles = Get-ChildItem $ProfilesRoot -Directory -EA SilentlyContinue |
  Where-Object { $_.Name -notlike '*.bak*' -and $_.Name -ne 'node_modules' -and (Test-Path (Join-Path $_.FullName 'package.json')) } |
  Select-Object -ExpandProperty Name

if ($allProfiles.Count -eq 0) { Die "profiles 目录下没有任何可用 profile" }
Say ("    现有 profile: " + ($allProfiles -join ', '))

# 兼容 `-File` 传参：powershell -File install.ps1 -Profile web,desktop 会把 "web,desktop" 当作单个字符串
$Profile = @($Profile | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })

if ($Profile.Count -eq 0) {
  # 默认（傻瓜模式）：只装 web 与 desktop —— 这两个是本插件的目标端。
  # 不默认 all，避免把插件塞进 xiufu / 其他专用 profile（那些 profile 有各自用途）。
  $preferred = @($allProfiles | Where-Object { $_ -eq 'web' -or $_ -eq 'desktop' })
  if ($preferred.Count -gt 0) {
    $Profile = $preferred
    Ok "未指定 -Profile，按默认安装到：$($Profile -join ', ')"
  } else {
    $Profile = @($allProfiles)
    Warn "本机没有 web / desktop profile，改为安装到全部现有 profile：$($Profile -join ', ')"
  }
} elseif ($Profile -contains 'all') {
  $Profile = @($allProfiles)
  Ok "目标 = 全部 profile：$($Profile -join ', ')"
} else {
  $bad = $Profile | Where-Object { $allProfiles -notcontains $_ }
  if ($bad) { Die "profile 不存在：$($bad -join ', ')；可选：$($allProfiles -join ', ')" }
  Ok "目标 profile：$($Profile -join ', ')"
}

# ---------------------------------------------------------------- 4 插件落盘
Step 4 '插件落盘（复制到本机固定目录，脱离安装包位置）'
if (-not $PluginDir) { $PluginDir = Join-Path $DshHome "local-plugins\$PluginName" }
$PluginDir = [System.IO.Path]::GetFullPath($PluginDir)

if (Test-Path $PluginDir) {
  if (-not $Force) {
    $existingVer = 'unknown'
    $ep = Join-Path $PluginDir 'package.json'
    if (Test-Path $ep) { try { $existingVer = (Get-Content $ep -Raw -Encoding UTF8 | ConvertFrom-Json).version } catch {} }
    Warn "已存在 $PluginDir (v$existingVer)，跳过复制（加 -Force 可强制覆盖）"
  } else {
    $bak = "$PluginDir.bak-$Stamp"
    if ($PSCmdlet.ShouldProcess($PluginDir, "备份并覆盖")) {
      Move-Item $PluginDir $bak -Force
      Ok "旧版本已备份：$bak"
    }
  }
}
if (-not (Test-Path $PluginDir)) {
  if ($PSCmdlet.ShouldProcess($PluginDir, "复制插件")) {
    New-Item -ItemType Directory -Path (Split-Path $PluginDir -Parent) -Force | Out-Null
    if ($SrcPlugin -eq $PackageRoot) {
      # 源码布局：只复制插件本体白名单，不把 .git / legacy / 安装器一起搬进去
      New-Item -ItemType Directory -Path $PluginDir -Force | Out-Null
      $keepFiles = @('index.js','client.js','package.json','cordis.patch.yml','cordis.override.patch.yml',
                     'icon.svg','LICENSE','THIRD-PARTY-NOTICES.md','README.md','README-zh.md',
                     'README-es.md','README-pt.md','README-hi.md')
      foreach ($f in $keepFiles) {
        $sp = Join-Path $SrcPlugin $f
        if (Test-Path $sp) { Copy-Item $sp (Join-Path $PluginDir $f) -Force }
      }
      foreach ($d in @('prompts','locale','scripts','tests','node_modules')) {
        $sp = Join-Path $SrcPlugin $d
        if (Test-Path $sp) { Copy-Item $sp (Join-Path $PluginDir $d) -Recurse -Force }
      }
      Ok "已复制插件本体（源码布局）到 $PluginDir"
    } else {
      Copy-Item $SrcPlugin $PluginDir -Recurse -Force
      Ok "已复制到 $PluginDir"
    }
  }
}
$PluginDir = (Resolve-Path $PluginDir).Path

# 插件自检：语法 + 依赖解析
$chk = Invoke-Native -Exe $NodeExe -ArgList @("--check", (Join-Path $PluginDir 'index.js'))
if ($chk.ExitCode -ne 0) { Die "index.js 语法检查失败：$($chk.Output)" }
$chk2 = Invoke-Native -Exe $NodeExe -ArgList @("--check", (Join-Path $PluginDir 'client.js'))
if ($chk2.ExitCode -ne 0) { Die "client.js 语法检查失败：$($chk2.Output)" }
Ok "index.js / client.js 语法检查通过"

$probeScript = Join-Path $PackageRoot 'tools\probe-plugin.mjs'
$probeRes = Invoke-Native -Exe $NodeExe -ArgList @($probeScript, $PluginDir)
$probeOut = $probeRes.Output.Trim()
if ($probeOut -notmatch '^PROBE_OK') { Die "插件模块加载失败（离线依赖未生效）：$probeOut" }
Ok "模块加载成功，导出：$($probeOut -replace '^PROBE_OK:','')"

# ---------------------------------------------------------------- 5 逐 profile 挂载
$results = @()
foreach ($prof in $Profile) {
  $profDir = Join-Path $ProfilesRoot $prof
  Step "5.$prof" "挂载到 profile [$prof]"

  # 5.1 备份
  $pkgPath = Join-Path $profDir 'package.json'
  $bakPath = "$pkgPath.bak-$Stamp-$PluginName"
  Copy-Item $pkgPath $bakPath -Force
  Ok "package.json 已备份：$(Split-Path $bakPath -Leaf)"

  # 5.2 写声明（dependencies + bundles）
  $patchScript = Join-Path $PackageRoot 'tools\patch-profile.mjs'
  $patchRes = Invoke-Native -Exe $NodeExe -ArgList @($patchScript, $profDir, $PluginName, $PluginDir)
  $patchOut = $patchRes.Output.Trim()
  if ($patchRes.ExitCode -ne 0) { Warn "声明写入失败：$patchOut"; $results += [pscustomobject]@{Profile=$prof; Mount='FAIL'; Declare='FAIL'; Verify='FAIL'}; continue }
  Ok "package.json 声明：$patchOut"

  # 5.3 建 Junction（不用 symlink）
  $nmDir = Join-Path $profDir 'node_modules'
  if (-not (Test-Path $nmDir)) { New-Item -ItemType Directory -Path $nmDir -Force | Out-Null }
  $junction = Join-Path $nmDir $PluginName
  if (Test-Path $junction) {
    $it = Get-Item $junction -Force
    if ($it.LinkType -eq 'Junction') { Ok "Junction 已存在 → $($it.Target)" }
    else { cmd /c rmdir /s /q "$junction" 2>$null; Ok "清理了同名实体目录" }
  }
  if (-not (Test-Path $junction)) {
    & cmd /c mklink /J "$junction" "$PluginDir" | Out-Null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $junction)) { Warn "Junction 创建失败"; $results += [pscustomobject]@{Profile=$prof; Mount='FAIL'; Declare='OK'; Verify='FAIL'}; continue }
  }
  $jt = (Get-Item $junction -Force).Target
  Ok "Junction: node_modules\$PluginName → $jt"

  # 5.4 校验一：从 profile 目录解析插件与内核 API
  $resolveRes = Invoke-Native -Exe $NodeExe -ArgList @("-e", "const {createRequire}=require('module');const r=createRequire('$(($profDir -replace '\\','/'))/package.json');const out=[];for(const m of ['fujiang-armor','@deepseek-ai/cordis','@deepseek-ai/dsh-tools','@deepseek-ai/schemastery']){try{out.push(m+'='+require(r.resolve(m+'/package.json')).version)}catch(e){out.push(m+'=MISSING')}}console.log(out.join(' '))")
$resolveOut = $resolveRes.Output.Trim()
  if ($resolveOut -match 'fujiang-armor=MISSING') { Warn "从 profile 解析插件失败：$resolveOut"; $results += [pscustomobject]@{Profile=$prof; Mount='OK'; Declare='OK'; Verify='FAIL'}; continue }
  Ok "解析链：$resolveOut"

  # 5.5 校验二：内核合成配置里是否入栈
  #   desktop profile 由 Electron 独占管理，CLI 拒绝读取（error: profile "desktop" is managed
  #   exclusively by the Electron application），此时降级为「静态声明校验」，同样算通过。
  $dshBin = Join-Path $DshHome 'profiles\node_modules\@deepseek-ai\dsh\lib\bin.js'
  $dump = 'SKIP'
  if (Test-Path $dshBin) {
    $dumpRes = Invoke-Native -Exe $NodeExe -ArgList @($dshBin, "--profile", $prof, "--dump-config")
    $dumpOut = $dumpRes.Output
    if ($dumpOut -match 'managed exclusively by the Electron application') {
      $dump = 'ELECTRON'
      Ok "该 profile 由 Electron 独占管理，改用静态声明校验（等效）"
    } elseif ($dumpOut -match "id:\s*$PluginName") {
      $dump = 'OK'
      $ordLine = ($dumpOut -split "`n" | Select-String "globalOrder").Line | Select-Object -First 1
      Ok "内核合成配置已包含 $PluginName $($ordLine -replace '\s+',' ')"
    } else {
      $dump = 'MISS'
      Warn "内核合成配置未见 $PluginName（可能需要重启 DSH，或 bundles 未生效）"
    }
  } else { Warn "找不到 dsh CLI（$dshBin），跳过合成配置校验" }

  # 5.5b pnpm-lock 账本同步（关键：不做这步，将来任何一次 pnpm install 都会把
  #      node_modules\<插件> 的 Junction 抹掉，插件静默失联、日志零 warn）
  $lockScript = Join-Path $PackageRoot 'tools\sync-lock.mjs'
  if (Test-Path $lockScript) {
    $lockRes = Invoke-Native -Exe $NodeExe -ArgList @($lockScript, $profDir, $PluginName, $PluginDir)
    $lockOut = $lockRes.Output.Trim()
    if ($lockOut -match '^PATCHED') { Ok "pnpm-lock 账本已写入（$($lockOut -replace '^PATCHED\s*','')）" }
    elseif ($lockOut -match '^NOCHANGE') { Ok "pnpm-lock 账本已含条目（未改动）" }
    elseif ($lockOut -match '^NOLOCK') { Ok "该 profile 无 pnpm-lock.yaml，跳过账本同步" }
    elseif ($lockOut -match '^NOTARGET') { Ok "账本安全闸：声明未生效，跳过" }
    else { Warn "pnpm-lock 账本同步异常：$lockOut" }
  } else { Warn "缺少 tools\sync-lock.mjs，跳过 pnpm-lock 账本同步" }

  # 5.6 静态声明校验（对 Electron 独占 profile 是唯一可行判据）
  $staticPkg = Get-Content (Join-Path $profDir 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  $inBundles = @($staticPkg.dsh.profile.bundles) -contains $PluginName
  $inDeps    = $staticPkg.dependencies.PSObject.Properties.Name -contains $PluginName
  if ($inBundles -and $inDeps) { Ok "静态声明校验：bundles + dependencies 均已包含 $PluginName" }
  else { Warn "静态声明校验不完整：bundles=$inBundles dependencies=$inDeps"; $dump = 'FAIL' }

  $results += [pscustomobject]@{Profile=$prof; Mount='OK'; Declare='OK'; Verify=$dump}
}

# ---------------------------------------------------------------- 6 汇总
Step 6 '安装结果汇总'
Write-Host ""
$results | Format-Table -AutoSize | Out-String -Width 100 | Write-Host

$failed = @($results | Where-Object { $_.Mount -ne 'OK' -or $_.Declare -ne 'OK' -or $_.Verify -eq 'FAIL' })
if ($failed.Count -gt 0) {
  Say "==================================================" Red
  Say "  安装未完全成功，失败 profile：$(($failed.Profile) -join ', ')" Red
  Say "  回滚方式：把对应 profile 的 package.json.bak-$Stamp-$PluginName 改回 package.json，" Red
  Say "            并删除 node_modules\$PluginName 目录（cmd /c rmdir /s /q）。" Red
  Say "==================================================" Red
  exit 1
}

Say "==================================================" Green
Say "  安装成功！目标 profile：$(($results.Profile) -join ', ')" Green
Say "  插件目录：$PluginDir" Green
Say "==================================================" Green
Write-Host ""
Say "下一步（必须）：" Yellow
Say "  1) 完全退出并重启 DSH（桌面端关窗口 → 退出托盘 → 重新打开）" Yellow
Say "  2) 重启后新建会话，输入任意消息，系统提示词会注入「富江」人格" Yellow
Say "  3) 自检：让模型调用 fujiang_profile 工具，应返回 pluginVersion 0.4.5" Yellow
Write-Host ""
Say "卸载：powershell -ExecutionPolicy Bypass -File uninstall.ps1 -Profile $((($results.Profile) -join ','))" Gray
exit 0