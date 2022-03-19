# WSL Network Configuration Script
# Run at startup to configure NAT and port forwarding

# Wait for WSL adapter to be ready
Start-Sleep -Seconds 10

# Find WSL adapter (name may vary)
$wslAdapter = Get-NetAdapter | Where-Object { $_.Name -like '*WSL*' -and $_.Status -eq 'Up' } | Select-Object -First 1
if (-not $wslAdapter) {
    Write-Host "WSL adapter not found, exiting"
    exit 1
}
$adapterName = $wslAdapter.Name

# Remove old NAT config
Remove-NetNat -Name WSLNat -ErrorAction SilentlyContinue -Confirm:$false

# Check if 10.0.0.1 already exists on the adapter
$existingIP = Get-NetIPAddress -InterfaceAlias $adapterName -IPAddress '10.0.0.1' -ErrorAction SilentlyContinue
if (-not $existingIP) {
    # Add 10.0.0.1 to the WSL adapter
    New-NetIPAddress -InterfaceAlias $adapterName -IPAddress 10.0.0.1 -PrefixLength 24 -ErrorAction SilentlyContinue
}

# Create NAT
New-NetNat -Name WSLNat -InternalIPInterfaceAddressPrefix 10.0.0.0/24 -ErrorAction SilentlyContinue

# Port forwarding
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0 2>&1 | Out-Null
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=10.0.0.20
