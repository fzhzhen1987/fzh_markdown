# C:\Tools\wsl-net-fix.ps1
# WSL 网络一键修复 — Win10 / Win11 通用
#
# 用途:
#   1) AtLogon 计划任务自动跑(开机登录后自启 WSL + 设 IP)
#   2) 任何时候 SSH 不通,在管理员 PowerShell 里跑这个脚本一键修复
#
# 设计原则:
#   - 每一步都先 idempotent 检查,已对就跳过(日志里看到一连串 skipping 是正常)
#   - 任一项被破坏时它都能修(IP / NAT / portproxy / 防火墙)
#   - 全程写日志到 C:\Tools\wsl-net-fix.log,出问题翻日志立刻看到哪步失败
#
# 必须以管理员身份运行(New-NetIPAddress / New-NetNat / New-NetFirewallRule 都要 admin)。

$ErrorActionPreference = 'Stop'

# === 配置参数(改这里就够了)===
$LogFile           = 'C:\Tools\wsl-net-fix.log'
$StaticIP          = '10.0.0.1'             # Windows 侧 WSL 网卡 IP
$PrefixLength      = 24
$NatName           = 'WSLNat'
$NatPrefix         = '10.0.0.0/24'
$WslIP             = '10.0.0.20'            # WSL 内部 IP
$WslPort           = 22                     # WSL 内 sshd 监听端口
$ListenPort        = 2222                   # Windows 侧对外监听端口
$FwRuleName        = "WSL SSH $ListenPort"
$MaxAdapterWaitSec = 60                     # 等 vEthernet (WSL) 出现的最长秒数

function Write-Log {
    param([string]$Msg)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts $Msg" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Write-Host "$ts $Msg"
}

# 清旧日志(保留最近一次运行)
'' | Out-File -FilePath $LogFile -Encoding UTF8
Write-Log '=== wsl-net-fix start ==='

# --- 1) 唤醒 WSL,触发 vEthernet (WSL) 网卡创建 ---
# wsl.exe 同步等到 VM 起来才返回;若已起来则只是跑个 echo,无副作用。
# 注意:计划任务必须以"用户账户"跑这一步,SYSTEM 跑会报 WSL_E_LOCAL_SYSTEM_NOT_SUPPORTED。
Write-Log 'Starting WSL via wsl.exe -- echo wsl-up'
try {
    wsl.exe -- echo wsl-up | Out-Null
    Write-Log 'WSL startup command returned'
} catch {
    Write-Log "WSL start failed: $_"
}

# --- 2) 等 vEthernet (WSL) 网卡(最多 60s 重试)---
# 用变量取网卡对象,避开 -InterfaceAlias 'vEthernet (WSL)' 字面量
# 因为 firewall 模式下名字会变成 'vEthernet (WSL (Hyper-V firewall))',字面量会查空。
$wsl = $null
$waited = 0
while ($waited -lt $MaxAdapterWaitSec) {
    $wsl = Get-NetAdapter -IncludeHidden |
           Where-Object { $_.Name -like 'vEthernet (WSL*' -and $_.Status -eq 'Up' } |
           Select-Object -First 1
    if ($wsl) { break }
    Start-Sleep -Seconds 2
    $waited += 2
}
if (-not $wsl) {
    Write-Log "ERROR: WSL adapter not found after $MaxAdapterWaitSec s — exit"
    exit 1
}
Write-Log "Adapter found: $($wsl.Name) ifIndex=$($wsl.ifIndex) (waited ${waited}s)"

# --- 3) 修 IP(已有 10.0.0.1 跳过,缺失则清掉所有 IPv4 重设)---
$has = Get-NetIPAddress -InterfaceIndex $wsl.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
       Where-Object IPAddress -eq $StaticIP
if ($has) {
    Write-Log "IP $StaticIP already set on adapter, skipping"
} else {
    Write-Log "IP $StaticIP missing, resetting all IPv4 on adapter"
    try {
        Get-NetIPAddress -InterfaceIndex $wsl.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
          Remove-NetIPAddress -Confirm:$false
        New-NetIPAddress -InterfaceIndex $wsl.ifIndex -IPAddress $StaticIP -PrefixLength $PrefixLength | Out-Null
        Write-Log "IP $StaticIP/$PrefixLength set"
    } catch {
        Write-Log "ERROR setting IP: $_"
    }
}

# --- 4) 修 NAT(缺失才创建;NetNat 是系统全局资源,一台机只能一条相同前缀)---
if (Get-NetNat -Name $NatName -ErrorAction SilentlyContinue) {
    Write-Log "NAT '$NatName' exists, skipping"
} else {
    Write-Log "NAT '$NatName' missing, creating"
    try {
        New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $NatPrefix | Out-Null
        Write-Log "NAT created: $NatPrefix"
    } catch {
        Write-Log "ERROR creating NAT: $_"
    }
}

# --- 5) 修 portproxy(规则不对就重建)---
$existing = (netsh interface portproxy show v4tov4) | Out-String
$pattern  = "0\.0\.0\.0\s+$ListenPort\s+$([regex]::Escape($WslIP))\s+$WslPort"
if ($existing -match $pattern) {
    Write-Log "portproxy 0.0.0.0:$ListenPort -> ${WslIP}:$WslPort already correct, skipping"
} else {
    Write-Log "portproxy missing or wrong, recreating"
    netsh interface portproxy delete v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 2>&1 | Out-Null
    $r = netsh interface portproxy add v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 connectport=$WslPort connectaddress=$WslIP 2>&1
    Write-Log "portproxy add result: $r"
}

# --- 6) 修防火墙规则(缺失才加)---
if (Get-NetFirewallRule -DisplayName $FwRuleName -ErrorAction SilentlyContinue) {
    Write-Log "Firewall rule '$FwRuleName' exists, skipping"
} else {
    Write-Log "Firewall rule '$FwRuleName' missing, creating"
    try {
        New-NetFirewallRule -DisplayName $FwRuleName `
          -Direction Inbound -Protocol TCP -LocalPort $ListenPort -Action Allow | Out-Null
        Write-Log "Firewall rule created: TCP $ListenPort allow inbound"
    } catch {
        Write-Log "ERROR creating firewall rule: $_"
    }
}

Write-Log '=== wsl-net-fix done ==='
