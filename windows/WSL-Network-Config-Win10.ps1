# WSL Network Configuration Script for Windows 10
# Run at user logon to configure static IP, NAT and port forwarding
#
# Win10 特殊说明：
# - Win10 的 WSL 计划任务必须使用用户账户运行（不能用 SYSTEM）
# - 因为 SYSTEM 账户无法启动 WSL（WSL_E_LOCAL_SYSTEM_NOT_SUPPORTED）
# - 触发器使用 AtLogon（用户登录时）而非 AtStartup（系统启动时）

$LogFile = "C:\Scripts\WSL-Network-Config.log"
$MaxWaitSeconds = 120
$AdapterName = "vEthernet (WSL)"
$StaticIP = "10.0.0.1"
$PrefixLength = 24
$WslIP = "10.0.0.20"
$SshPort = 22
$ExternalPort = 2222

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Clear old log
"" | Out-File -FilePath $LogFile -Encoding UTF8

Write-Log "=== Script started ==="
Write-Log "Target: $AdapterName = $StaticIP/$PrefixLength"

# Start WSL to trigger adapter creation (requires user account, not SYSTEM)
Write-Log "Starting WSL to create adapter..."
$wslResult = wsl.exe --exec echo "WSL started" 2>&1
Write-Log "WSL start result: $wslResult"

# Wait for WSL adapter to appear and be ready
Write-Log "Waiting for adapter..."
$waited = 0
while ($waited -lt $MaxWaitSeconds) {
    $adapter = Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue
    if ($adapter -and $adapter.Status -eq 'Up') {
        Write-Log "Adapter found and up after $waited seconds"
        break
    }
    Start-Sleep -Seconds 2
    $waited += 2
}

if ($waited -ge $MaxWaitSeconds) {
    Write-Log "ERROR: Adapter not found after $MaxWaitSeconds seconds"
    exit 1
}

# Give it a moment to stabilize
Start-Sleep -Seconds 2

# Get current IP
$currentIP = Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($currentIP) {
    Write-Log "Current IP: $($currentIP.IPAddress)/$($currentIP.PrefixLength)"
}

# Remove all existing IPv4 addresses
Write-Log "Removing existing IP configuration..."
try {
    Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        ForEach-Object {
            Write-Log "Removing IP: $($_.IPAddress)"
            Remove-NetIPAddress -InputObject $_ -Confirm:$false -ErrorAction Stop
        }
    Write-Log "IP removal completed"
} catch {
    Write-Log "IP removal error: $_"
}

# Wait a moment
Start-Sleep -Seconds 1

# Add new IP
Write-Log "Adding IP $StaticIP/$PrefixLength..."
try {
    $newIP = New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $StaticIP -PrefixLength $PrefixLength -ErrorAction Stop
    Write-Log "IP added successfully"
} catch {
    Write-Log "ERROR adding IP: $_"
    exit 1
}

# Configure NAT
Write-Log "Configuring NAT..."
try {
    Get-NetNat -Name "WSLNat" -ErrorAction SilentlyContinue | Remove-NetNat -Confirm:$false -ErrorAction SilentlyContinue
    New-NetNat -Name "WSLNat" -InternalIPInterfaceAddressPrefix "10.0.0.0/24" -ErrorAction Stop | Out-Null
    Write-Log "NAT configured"
} catch {
    Write-Log "NAT error: $_"
}

# Configure port forwarding
Write-Log "Configuring port forwarding $ExternalPort -> $WslIP`:$SshPort..."
netsh interface portproxy delete v4tov4 listenport=$ExternalPort listenaddress=0.0.0.0 2>&1 | Out-Null
$portproxyResult = netsh interface portproxy add v4tov4 listenport=$ExternalPort listenaddress=0.0.0.0 connectport=$SshPort connectaddress=$WslIP 2>&1
Write-Log "Port forwarding result: $portproxyResult"

# Verify final configuration
$finalIP = Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($finalIP) {
    Write-Log "Final IP: $($finalIP.IPAddress)/$($finalIP.PrefixLength)"
    if ($finalIP.IPAddress -eq $StaticIP) {
        Write-Log "SUCCESS: IP configured correctly"
    } else {
        Write-Log "WARNING: IP mismatch! Expected $StaticIP, got $($finalIP.IPAddress)"
    }
} else {
    Write-Log "ERROR: No IP address found after configuration"
}

Write-Log "=== Script completed ==="
