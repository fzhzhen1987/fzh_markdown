# WSL 固定 IP 配置指南 - 外部访问版

## 一、WSL 内部配置

### 1.1 创建配置文件
```bash
# 编辑 wsl.conf
sudo nano /etc/wsl.conf
```

内容：
```ini
[boot]
systemd=true
command = /etc/wsl-network.sh

[network]
generateResolvConf = false
```

### 1.2 创建网络脚本
```bash
# 创建脚本
sudo nano /etc/wsl-network.sh
```

内容：
```bash
#!/bin/bash
CURRENT_IP=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
FIXED_IP="10.0.0.20"

if [ "$CURRENT_IP" != "$FIXED_IP" ]; then
    CUR_NETMASK=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | head -1 | cut -d'/' -f2)
    [ -z "$CUR_NETMASK" ] && CUR_NETMASK="20"
    
    ip addr del $CURRENT_IP/$CUR_NETMASK dev eth0 2>/dev/null || true
    ip addr add $FIXED_IP/24 brd 10.0.0.255 dev eth0
fi

if ! ip route | grep -q "default"; then
    ip route add default via 10.0.0.1 dev eth0
fi
```

```bash
# 设置执行权限
sudo chmod +x /etc/wsl-network.sh
```

### 1.3 配置 DNS
```bash
# 编辑 DNS
sudo nano /etc/resolv.conf
```

内容：
```
nameserver 8.8.8.8
nameserver 8.8.4.4
```

```bash
# 防止被覆盖
sudo chattr +i /etc/resolv.conf
```

## 二、Windows 配置（管理员 PowerShell）

### 2.1 查找 WSL 网卡名称
```powershell
# 显示所有虚拟网卡
Get-NetAdapter | Where-Object {$_.Name -like "vEthernet*"} | Format-Table Name, Status
```

### 2.2 配置 WSL 网卡和 NAT
```powershell
# 设置 WSL 网卡名称（根据上面查到的名称修改）
$wslAdapter = "vEthernet (WSL (Hyper-V firewall))"

# 查看当前 IP
Write-Host "当前 IP:" -ForegroundColor Yellow
Get-NetIPAddress -InterfaceAlias $wslAdapter -AddressFamily IPv4

# 删除现有 IP
Get-NetIPAddress -InterfaceAlias $wslAdapter -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false

# 设置新 IP
New-NetIPAddress -InterfaceAlias $wslAdapter -IPAddress 10.0.0.1 -PrefixLength 24

# 删除旧 NAT（避免冲突）
Remove-NetNat -Name "WSLNat" -Confirm:$false -ErrorAction SilentlyContinue

# 创建新 NAT
New-NetNat -Name "WSLNat" -InternalIPInterfaceAddressPrefix 10.0.0.0/24

# 启用 IP 转发
$wslIfIndex = (Get-NetAdapter -Name $wslAdapter).ifIndex
Set-NetIPInterface -InterfaceIndex $wslIfIndex -Forwarding Enabled

Write-Host "基础配置完成！" -ForegroundColor Green
```

### 2.3 配置端口转发
```powershell
# 添加 SSH 端口转发（外部 2222 -> WSL 22）
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=10.0.0.20

# 查看端口转发规则
netsh interface portproxy show all
```

### 2.4 配置防火墙规则
```powershell
# 删除旧的防火墙规则
Remove-NetFirewallRule -DisplayName "WSL SSH*" -ErrorAction SilentlyContinue

# 创建新的防火墙规则
New-NetFirewallRule -DisplayName "WSL SSH Port 2222" -Direction Inbound -LocalPort 2222 -Protocol TCP -Action Allow -Profile Any

# 验证防火墙规则
Get-NetFirewallRule -DisplayName "WSL SSH*" | Format-Table DisplayName, Enabled, LocalPort, Action
```

## 三、重启和验证

### 3.1 重启 WSL
```powershell
wsl --shutdown
Start-Sleep -Seconds 3
wsl
```

### 3.2 WSL 内部验证
```bash
# 查看 IP
ip addr show eth0 | grep inet

# 测试网络
ping -c 2 8.8.8.8

# 确保 SSH 服务运行
sudo systemctl status ssh
# 如果未运行，启动它
sudo systemctl start ssh
sudo systemctl enable ssh
```

### 3.3 Windows 本机验证
```powershell
# 查看 WSL 网卡 IP
Get-NetIPAddress -InterfaceAlias $wslAdapter -AddressFamily IPv4

# Ping WSL
ping 10.0.0.20

# 查看端口转发
netsh interface portproxy show all

# 测试本机 SSH 连接
ssh -p 2222 username@localhost
```

### 3.4 外部主机验证
在另一台主机上：
```bash
# 假设 Windows 主机 IP 是 192.168.1.100
ssh -p 2222 username@192.168.1.100

# 或使用 telnet 测试端口
telnet 192.168.1.100 2222
```

## 四、其他服务配置（可选）

### 4.1 Web 服务
```powershell
# HTTP 端口转发
netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=80 connectaddress=10.0.0.20
New-NetFirewallRule -DisplayName "WSL HTTP" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow -Profile Any

# HTTPS 端口转发
netsh interface portproxy add v4tov4 listenport=8443 listenaddress=0.0.0.0 connectport=443 connectaddress=10.0.0.20
New-NetFirewallRule -DisplayName "WSL HTTPS" -Direction Inbound -LocalPort 8443 -Protocol TCP -Action Allow -Profile Any
```

### 4.2 查看所有配置
```powershell
# 所有端口转发
netsh interface portproxy show all

# 所有防火墙规则
Get-NetFirewallRule -DisplayName "WSL*" | Format-Table DisplayName, LocalPort, Action, Enabled
```

### 4.3 删除端口转发（如需要）
```powershell
# 删除特定端口转发
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0

# 删除防火墙规则
Remove-NetFirewallRule -DisplayName "WSL SSH Port 2222"
```

## 五、故障排查

### 5.1 无法从外部访问
1. 检查 Windows 防火墙是否开启
2. 检查端口转发：`netsh interface portproxy show all`
3. 检查防火墙规则：`Get-NetFirewallRule -DisplayName "WSL*"`
4. 确认 Windows 主机 IP：`ipconfig`
5. 确认 WSL 内服务正在监听：`sudo ss -tlnp | grep :22`

### 5.2 WSL 无法上网
```bash
# 检查路由
ip route
# 如果没有默认路由，添加
sudo ip route add default via 10.0.0.1 dev eth0

# 检查 DNS
nslookup google.com
# 如需修改 DNS
sudo chattr -i /etc/resolv.conf
sudo nano /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
```

---

**网络拓扑**：
```
外部主机 --> Windows(192.168.x.x:2222) --> NAT/端口转发 --> WSL(10.0.0.20:22)
```

**关键配置**：
- WSL 固定 IP：`10.0.0.20`
- Windows 网关：`10.0.0.1`
- 外部访问端口：`2222`（可修改）
- 所有 PowerShell 命令需管理员权限
