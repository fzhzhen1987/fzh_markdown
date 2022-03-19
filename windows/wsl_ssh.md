# WSL 固定 IP + 外部 SSH 访问配置手顺书

## 目标

让外部设备通过 Windows 主机 IP:2222 SSH 连接到 WSL

```
外部主机 → Windows(192.168.x.x:2222) → NAT/端口转发 → WSL(10.0.0.20:22)
```

## 关键参数

| 项目 | 值 |
|------|-----|
| WSL 固定 IP | 10.0.0.20 |
| Windows 网关 IP | 10.0.0.1 |
| 子网掩码 | /24 (255.255.255.0) |
| 外部访问端口 | 2222 |
| WSL SSH 端口 | 22 |
| WSL 用户 | mav |

---

## 第一阶段：信息收集

### 1.1 查看 Windows WSL 虚拟网卡

```powershell
Get-NetAdapter | Format-Table Name, InterfaceDescription, Status -AutoSize
```

结果：`vEthernet (WSL)` - Hyper-V Virtual Ethernet Adapter - Up

### 1.2 查看 WSL 当前 IP

```bash
ip addr show eth0
```

### 1.3 检查 SSH 服务状态

```bash
systemctl status ssh
```

### 1.4 查看 wsl.conf

```bash
cat /etc/wsl.conf
```

---

## 第二阶段：WSL 内部配置

### 2.1 创建 /etc/wsl.conf

```bash
sudo tee /etc/wsl.conf << 'EOF'
[boot]
systemd=true
command=/etc/wsl-network.sh

[network]
generateResolvConf=false
generateHosts=true
EOF
```

**说明：**
- `systemd=true` - 启用 systemd，让 SSH 服务可以自动启动
- `command=/etc/wsl-network.sh` - WSL 启动时执行网络配置脚本
- `generateResolvConf=false` - 禁用自动生成 resolv.conf

### 2.2 创建固定 IP 启动脚本 /etc/wsl-network.sh

```bash
sudo tee /etc/wsl-network.sh << 'EOF'
#!/bin/bash
# WSL 固定 IP 配置脚本
ip addr flush dev eth0
ip addr add 10.0.0.20/24 dev eth0
ip link set eth0 up
ip route add default via 10.0.0.1
EOF

sudo chmod +x /etc/wsl-network.sh
```

### 2.3 配置并锁定 /etc/resolv.conf

```bash
# 解除可能存在的锁定
sudo chattr -i /etc/resolv.conf 2>/dev/null || true

# 删除符号链接或文件
sudo rm -f /etc/resolv.conf

# 创建新的 resolv.conf
sudo tee /etc/resolv.conf << 'EOF'
nameserver 223.5.5.5
nameserver 114.114.114.114
nameserver 8.8.8.8
EOF

# 锁定文件防止被覆盖
sudo chattr +i /etc/resolv.conf
```

### 2.4 启用 SSH 服务开机自启

```bash
sudo systemctl enable ssh
```

---

## 第三阶段：Windows 配置（需管理员权限）

### 3.1 清理旧配置

```powershell
# 删除旧的 NAT
Remove-NetNat -Name WSLNat -ErrorAction SilentlyContinue

# 删除旧的 IP 配置
Get-NetIPAddress -InterfaceAlias 'vEthernet (WSL)' -ErrorAction SilentlyContinue | Remove-NetIPAddress -ErrorAction SilentlyContinue
```

### 3.2 配置 WSL 网卡 IP 为 10.0.0.1

```powershell
New-NetIPAddress -InterfaceAlias 'vEthernet (WSL)' -IPAddress 10.0.0.1 -PrefixLength 24
```

### 3.3 创建 NAT 规则

```powershell
New-NetNat -Name WSLNat -InternalIPInterfaceAddressPrefix 10.0.0.0/24
```

### 3.4 配置端口转发

```powershell
# 删除旧规则
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0

# 添加新规则：0.0.0.0:2222 → 10.0.0.20:22
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=10.0.0.20

# 查看端口转发规则
netsh interface portproxy show v4tov4
```

### 3.5 添加防火墙入站规则

```powershell
# 删除旧规则
Remove-NetFirewallRule -DisplayName 'WSL SSH 2222' -ErrorAction SilentlyContinue

# 添加新规则
New-NetFirewallRule -DisplayName 'WSL SSH 2222' -Direction Inbound -Protocol TCP -LocalPort 2222 -Action Allow
```

### 3.6 创建开机自动配置脚本

创建文件 `C:\Scripts\WSL-Network-Config.ps1`：

> **下载链接**: [WSL-Network-Config.ps1](./WSL-Network-Config.ps1)

```powershell
# WSL Network Configuration Script
# Run at startup to configure NAT and port forwarding

# Wait for WSL adapter
Start-Sleep -Seconds 5

# Remove old config
Remove-NetNat -Name WSLNat -ErrorAction SilentlyContinue
Get-NetIPAddress -InterfaceAlias 'vEthernet (WSL)' -ErrorAction SilentlyContinue | Remove-NetIPAddress -ErrorAction SilentlyContinue

# Configure IP
New-NetIPAddress -InterfaceAlias 'vEthernet (WSL)' -IPAddress 10.0.0.1 -PrefixLength 24 -ErrorAction SilentlyContinue

# Create NAT
New-NetNat -Name WSLNat -InternalIPInterfaceAddressPrefix 10.0.0.0/24 -ErrorAction SilentlyContinue

# Port forwarding
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0 2>&1 | Out-Null
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=10.0.0.20
```

### 3.7 创建计划任务（开机自动执行）

```powershell
# 删除旧任务
Unregister-ScheduledTask -TaskName 'WSL Network Config' -ErrorAction SilentlyContinue

# 创建新任务
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -File C:\Scripts\WSL-Network-Config.ps1'
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'WSL Network Config' -Action $action -Trigger $trigger -Principal $principal -Description 'Configure WSL NAT and port forwarding at startup'
```

---

## 第四阶段：重启验证

### 4.1 重启 WSL

```powershell
wsl --shutdown
```

然后重新打开 WSL 终端或执行 `wsl` 命令。

### 4.2 验证 WSL IP

```bash
ip addr show eth0
```

预期结果：`inet 10.0.0.20/24`

### 4.3 验证路由

```bash
ip route
```

预期结果：
```
default via 10.0.0.1 dev eth0
10.0.0.0/24 dev eth0 proto kernel scope link src 10.0.0.20
```

### 4.4 验证 SSH 服务

```bash
systemctl status ssh
```

预期结果：`Active: active (running)`

### 4.5 验证网络连通性

```bash
ping -c 2 223.5.5.5
```

### 4.6 从 Windows 测试 SSH 端口

```powershell
# 测试直连
Test-NetConnection -ComputerName 10.0.0.20 -Port 22

# 测试端口转发
Test-NetConnection -ComputerName 127.0.0.1 -Port 2222
```

### 4.7 SSH 连接测试

```bash
# 从 Windows 本机
ssh mav@10.0.0.20

# 从外部设备
ssh mav@<Windows主机IP> -p 2222
```

---

## 配置文件汇总

| 位置 | 文件 | 作用 |
|------|------|------|
| WSL | `/etc/wsl.conf` | WSL 启动配置 |
| WSL | `/etc/wsl-network.sh` | 固定 IP 脚本 |
| WSL | `/etc/resolv.conf` | DNS 配置（已锁定） |
| Windows | `C:\Scripts\WSL-Network-Config.ps1` | 开机网络配置脚本 |
| Windows | 计划任务 `WSL Network Config` | 开机自动执行脚本 |

---

## 故障排除

### 问题1：WSL 重启后 IP 不是 10.0.0.20

检查 `/etc/wsl.conf` 和 `/etc/wsl-network.sh` 是否存在且内容正确。

```bash
cat /etc/wsl.conf
cat /etc/wsl-network.sh
```

### 问题2：WSL 无法上网

1. 检查 Windows 网关 IP：
```powershell
Get-NetIPAddress -InterfaceAlias 'vEthernet (WSL)'
```

2. 检查 NAT 规则：
```powershell
Get-NetNat
```

3. 检查 resolv.conf：
```bash
cat /etc/resolv.conf
```

### 问题3：外部无法 SSH 连接

1. 检查端口转发：
```powershell
netsh interface portproxy show v4tov4
```

2. 检查防火墙规则：
```powershell
Get-NetFirewallRule -DisplayName 'WSL SSH 2222'
```

3. 检查 SSH 服务：
```bash
sudo systemctl status ssh
```

### 问题4：Windows 重启后配置丢失

1. 检查计划任务：
```powershell
Get-ScheduledTask -TaskName 'WSL Network Config'
```

2. 手动执行配置脚本：
```powershell
powershell -ExecutionPolicy Bypass -File C:\Scripts\WSL-Network-Config.ps1
```

### 问题5：resolv.conf 被覆盖

重新锁定：
```bash
sudo chattr -i /etc/resolv.conf
sudo rm /etc/resolv.conf
echo -e "nameserver 223.5.5.5\nnameserver 114.114.114.114\nnameserver 8.8.8.8" | sudo tee /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
```

### 问题6：Windows 重启后配置失效（SYSTEM 账户无法启动 WSL）

**症状**：
- Windows 重启后 WSL 无法上网
- `vEthernet (WSL)` 网卡 IP 不是 10.0.0.1，而是 172.x.x.x
- 计划任务运行结果显示失败（错误代码 -2147023829）

**根本原因**：

| 项目 | 问题 |
|------|------|
| 原计划任务触发器 | `AtStartup`（系统启动时） |
| 原运行账户 | SYSTEM |
| 失败原因 | **SYSTEM 账户无法启动 WSL**（`WSL_E_LOCAL_SYSTEM_NOT_SUPPORTED`） |
| 结果 | WSL 网卡不存在，脚本无法配置，静默失败 |

**解决方案**：

1. **更新计划任务配置**：

| 项目 | 修改前 | 修改后 |
|------|--------|--------|
| 触发器 | AtStartup (系统启动) | **AtLogon (用户登录)** |
| 运行账户 | SYSTEM | **当前用户** |
| 延迟 | 无/5秒 | **10秒** |

2. **更新计划任务命令**（管理员 PowerShell）：

```powershell
# 删除旧任务
Unregister-ScheduledTask -TaskName 'WSL Network Config' -Confirm:$false -ErrorAction SilentlyContinue

# 创建新任务（用户登录触发，当前用户账户）
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Scripts\WSL-Network-Config-Win10.ps1'
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$trigger.Delay = 'PT10S'  # 延迟10秒
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName 'WSL Network Config' -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Description 'Configure WSL NAT and port forwarding at user logon'
```

3. **更新配置脚本** `C:\Scripts\WSL-Network-Config-Win10.ps1`：

> **Win10 专用脚本下载**: [WSL-Network-Config-Win10.ps1](./WSL-Network-Config-Win10.ps1)

脚本改进内容：
- 先执行 `wsl.exe --exec echo` 触发网卡创建（需要用户账户权限）
- 循环等待网卡出现（最多 120 秒）
- 详细日志输出到 `C:\Scripts\WSL-Network-Config.log`
- 使用 try-catch 捕获错误
- 最终验证并记录结果

4. **添加 ICMP 防火墙规则**：

固定 IP + NAT 模式下，Windows 将 10.0.0.0/24 视为独立的外部网络，防火墙会阻止 ICMP 入站请求，导致 WSL 无法 ping 通 Windows 网关（10.0.0.1）。

```powershell
# 允许 WSL 子网的 ICMP 请求（管理员 PowerShell）
New-NetFirewallRule -DisplayName 'WSL ICMPv4 Allow' -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -RemoteAddress 10.0.0.0/24 -Action Allow
```

验证规则已创建：
```powershell
Get-NetFirewallRule -DisplayName 'WSL ICMPv4 Allow' | Format-List DisplayName, Enabled, Action
```

5. **重启后验证**：

```powershell
# 查看日志（成功标志：末尾显示 SUCCESS: IP configured correctly）
Get-Content C:\Scripts\WSL-Network-Config.log

# 验证 WSL 网卡 IP
Get-NetIPAddress -InterfaceAlias 'vEthernet (WSL)' -AddressFamily IPv4
```

6. **日志排错对照表**：

| 日志内容 | 问题 | 解决方案 |
|----------|------|----------|
| 日志不存在 | 计划任务未执行 | 检查任务计划程序 |
| `Adapter not found after 120 seconds` | WSL 启动失败 | 手动运行 `wsl` 后再执行脚本 |
| `ERROR adding IP` | IP 配置失败 | 查看具体错误信息 |
| `SUCCESS` 但 IP 不对 | 被其他程序覆盖 | 需进一步排查 |

7. **手动恢复命令（Win10）**：

```powershell
powershell -ExecutionPolicy Bypass -File C:\Scripts\WSL-Network-Config-Win10.ps1
```

---

## 快速恢复命令

如果配置丢失，按顺序执行：

**Windows（管理员 PowerShell）：**
```powershell
# 执行开机脚本
powershell -ExecutionPolicy Bypass -File C:\Scripts\WSL-Network-Config.ps1
```

**WSL：**
```bash
# 手动执行网络配置
sudo /etc/wsl-network.sh

# 启动 SSH
sudo systemctl start ssh
```

---

*文档创建日期：2026-01-22*
