<#
.SYNOPSIS
  富江破甲 (fujiang-armor) 通用卸载器。
.DESCRIPTION
  从指定 profile 摘除声明 + 删除 Junction；可选彻底删除插件落盘目录。
.PARAMETER Profile
  目标 profile 名，可多选；填 all 表示全部现有 profile。默认全部。
.PARAMETER DshHome
  手动指定 DSH 数据根目录（默认 %USERPROFILE%\.dsh）。
.PARAMETER PluginDir
  插件落盘目录（默认 <DshHome>\local-plugins\fujiang-armor）。
.PARAMETER Purge
  同时删除插件落盘目录。
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File uninstall.ps1
  powershell -ExecutionPolicy Bypass -File uninstall.ps1 -Profile web -Purge
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string[]]$Profile = @(),
  [string]$DshHome,
  [string]$PluginDir,
  [switch]$Purge
)

$ErrorActionPreference = 'Stop'
$PluginName = 'fujiang-armor'
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
# 兼容两种布局：Release ZIP（tools\ 在包根）与源码仓库（tools\ 同样在根）
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Say($m, $c='Gray'){ Write-Host $m -ForegroundColor $c }
function Step($n,$m){ Write-Host ""; Write-Host "[$n] $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "    [OK]   $m" -ForegroundColor Green }
function Warn($m){ Write-Host "    [WARN] $m" -ForegroundColor Yellow }
function Die($m){ Write-Host "    [FAIL] $m" -ForegroundColor Red; exit 1 }

Say "==================================================" DarkCyan
Say "  富江破甲 fujiang-armor  通用卸载器" DarkCyan
Say "==================================================" DarkCyan

Step 1 '定位 DSH 数据根目录'
if (-not $DshHome) {
  if ($env:DSH_HOME -and (Test-Path $env:DSH_HOME)) { $DshHome = $env:DSH_HOME }
  elseif (Test-Path (Join-Path $env:USERPROFILE '.dsh')) { $DshHome = Join-Path $env:USERPROFILE '.dsh' }
}
if (-not $DshHome -or -not (Test-Path $DshHome)) { Die "找不到 DSH 数据目录，请用 -DshHome 指定" }
$DshHome = (Resolve-Path $DshHome).Path
Ok "DSH_HOME = $DshHome"
$ProfilesRoot = Join-Path $DshHome 'profiles'

Step 2 '定位 Node 运行时'
$nodeCandidates = @()
$rtRoot = Join-Path $DshHome 'dsh-runtimes'
if (Test-Path $rtRoot) {
  $nodeCandidates += (Get-ChildItem $rtRoot -Directory -EA SilentlyContinue |
    ForEach-Object { Join-Path $_.FullName 'dependencies\node\bin\node.exe' } | Where-Object { Test-Path $_ })
}
$nodeCandidates += (Get-Command node -EA SilentlyContinue | ForEach-Object { $_.Source })
$NodeExe = $nodeCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $NodeExe) { Die "找不到 node.exe" }
Ok "node = $NodeExe"

Step 3 '选定目标 profile'
$allProfiles = Get-ChildItem $ProfilesRoot -Directory -EA SilentlyContinue |
  Where-Object { $_.Name -notlike '*.bak*' -and $_.Name -ne 'node_modules' -and (Test-Path (Join-Path $_.FullName 'package.json')) } |
  Select-Object -ExpandProperty Name
# 兼容 `-File` 传参：powershell -File uninstall.ps1 -Profile web,desktop 会传成单个字符串 "web,desktop"
$Profile = @($Profile | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($Profile.Count -eq 0) {
  # 与安装器对称：默认只处理 web 与 desktop，不碰 xiufu 等专用 profile
  $preferred = @($allProfiles | Where-Object { $_ -eq 'web' -or $_ -eq 'desktop' })
  if ($preferred.Count -gt 0) { $Profile = $preferred } else { $Profile = @($allProfiles) }
} elseif ($Profile -contains 'all') {
  $Profile = @($allProfiles)
}
$bad = $Profile | Where-Object { $allProfiles -notcontains $_ }
if ($bad) { Die "profile 不存在：$($bad -join ', ')" }
Ok "目标：$($Profile -join ', ')"

$results = @()
foreach ($prof in $Profile) {
  $profDir = Join-Path $ProfilesRoot $prof
  $pkgPath = Join-Path $profDir 'package.json'
  Step "4.$prof" "卸载 profile [$prof]"

  if (-not (Test-Path $pkgPath)) { Warn "无 package.json，跳过"; continue }
  Copy-Item $pkgPath "$pkgPath.bak-$Stamp-$PluginName-uninstall" -Force

  $patchScript = Join-Path $PackageRoot 'tools\patch-profile.mjs'
  $out = & $NodeExe $patchScript $profDir $PluginName 'unused' '--remove' 2>&1
  if ($LASTEXITCODE -ne 0) { Warn "声明清理失败：$out" }
  else { Ok "声明已清理：$out" }

  # 同步摘掉 pnpm-lock 账本条目（否则下次 pnpm install 会试图恢复一个已删除的 link）
  $lockScript = Join-Path $PackageRoot 'tools\sync-lock.mjs'
  if (Test-Path $lockScript) {
    $lockOut = & $NodeExe $lockScript $profDir $PluginName 'unused' '--remove' 2>&1
    $lockOut = "$lockOut".Trim()
    if ($lockOut -match '^REMOVED') { Ok "pnpm-lock 账本条目已移除" }
    elseif ($lockOut -match '^NOCHANGE') { Ok "pnpm-lock 账本本无该条目" }
    elseif ($lockOut -match '^NOLOCK') { Ok "无 pnpm-lock.yaml，跳过" }
    else { Warn "pnpm-lock 账本清理异常：$lockOut" }
  }

  $junction = Join-Path $profDir "node_modules\$PluginName"
  if (Test-Path $junction) {
    if ($PSCmdlet.ShouldProcess($junction, "删除 Junction")) {
      cmd /c rmdir "$junction" 2>$null
      if (Test-Path $junction) { cmd /c rmdir /s /q "$junction" 2>$null }
    }
    if (Test-Path $junction) { Warn "Junction 未删除：$junction" } else { Ok "Junction 已删除" }
  } else { Ok "无 Junction，无需处理" }

  $results += [pscustomobject]@{ Profile = $prof; Declare = 'OK'; Junction = 'OK' }
}

if ($Purge) {
  Step 5 '删除插件落盘目录'
  if (-not $PluginDir) { $PluginDir = Join-Path $DshHome "local-plugins\$PluginName" }
  if (Test-Path $PluginDir) {
    if ($PSCmdlet.ShouldProcess($PluginDir, "删除")) {
      $bak = "$PluginDir.bak-$Stamp"
      Move-Item $PluginDir $bak -Force
      Ok "已移出（可手动删除）：$bak"
    }
  } else { Ok "目录不存在" }
}

Step 6 '汇总'
$results | Format-Table -AutoSize | Out-String -Width 80 | Write-Host
Say "==================================================" Green
Say "  卸载完成。重启 DSH 后生效。" Green
Say "==================================================" Green
exit 0