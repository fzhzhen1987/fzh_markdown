# WSL SSH 连接手顺

## 0. 前提(先确认)

- WSL 是默认的 **NAT 网络模式**:`.wslconfig` 里**不能有** `networkingMode=mirrored`。
- WSL 的 **localhost 转发**是开着的(默认开):`.wslconfig` 里**不能有** `localhostForwarding=false`。本方法就是靠它把 Windows 的 `127.0.0.1:22` 送进 WSL。
- **不要用 Windows 自带的 OpenSSH Server**(Windows 侧的 `sshd` 服务)。它会占住 Windows 的 22 端口,转发到 `127.0.0.1:22` 就会连进 Windows 而不是 WSL。

确认(PowerShell):

```powershell
Get-Content "$env:USERPROFILE\.wslconfig" -ErrorAction SilentlyContinue   # 不应有 mirrored / localhostForwarding=false
Get-Service sshd -ErrorAction SilentlyContinue                              # 没有输出,或 Status 为 Stopped 才对
```

## 1. 设置（管理员 PowerShell，只做一次）

```powershell
# 清理旧规则:仅当以前用 listenaddress=192.168.11.211(固定网卡 IP)建过 2222 规则时需要;
# 没建过会提示找不到,可忽略
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=192.168.11.211

# 端口转发：所有网卡的 2222 → WSL 22
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=22 connectaddress=127.0.0.1

# 防火墙：放行 2222（不限来源，任何网段都能连）
Remove-NetFirewallRule -DisplayName 'WSL SSH 2222' -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'WSL SSH 2222' -Direction Inbound -Protocol TCP -LocalPort 2222 -Action Allow -Profile Any
```

WSL 内：

```bash
# 安装 sshd
sudo apt update && sudo apt install -y openssh-server

# 需要 systemd:确认 /etc/wsl.conf 的 [boot] 段有 systemd=true(新版 Ubuntu 默认已有)
grep -A3 '^\[boot\]' /etc/wsl.conf
# 没有的话:sudoedit /etc/wsl.conf 加上下面两行,然后在 PowerShell 里 wsl --shutdown 再重新进 WSL
#   [boot]
#   systemd=true

# 启动并设为开机自启
sudo systemctl enable --now ssh
```

确认：

```powershell
netsh interface portproxy show all      # 应有 0.0.0.0 2222 → 127.0.0.1 22
```

## 2. 连接方法

### 方法一：网线

```bash
ssh -p 2222 mav@192.168.11.211
```

### 方法二：Wi-Fi

1. 在 Windows 上查 Wi-Fi 的 IP：

   ```powershell
   (Get-NetIPAddress -InterfaceAlias 'Wi-Fi' -AddressFamily IPv4).IPAddress
   ```

2. 从同一 Wi-Fi 下的机器连接：

   ```bash
   ssh -p 2222 mav@<上面查到的IP>
   ```

## 3. 连不上时（管理员 PowerShell）

```powershell
wsl -- echo up
Restart-Service iphlpsvc
```

最常见的原因是 **WSL 空闲自动关机**:没有打开的 WSL 终端时,WSL 过一会儿会自动关掉,sshd 也跟着停;portproxy 不会唤醒 WSL。上面的 `wsl -- echo up` 只能临时拉起来,过一阵又会关。

## 4. 不让 WSL 空闲自动关机 ⚠️未实测

结论:执行一次 `wsl_keepalive_setup.ps1`(和本文件在同一个文件夹)。它在任务计划程序里登记任务 `WSL-KeepAlive`:每次登录 Windows 时,在 WSL 里启动一个**一直不退出的进程**(`sleep infinity`)。只要它在,WSL 就不会因为空闲而关机,sshd 一直在。

**表4-1　用到的两个脚本**

| No. | 文件 | 做什么 |
|---|---|---|
| 1 | `wsl_keepalive_setup.ps1` | 登记任务 `WSL-KeepAlive`,马上启动一次,15 秒后自己检查,显示 OK／NG |
| 2 | `wsl_keepalive_remove.ps1` | 删除这个任务,并结束还在跑的 `sleep infinity`,WSL 恢复成空闲时会自动关闭 |

### 4.1 先确认要一直开着的发行版名

脚本只让**一个**发行版一直开着,默认是 `Ubuntu-22.04`。先查自己 sshd 装在哪个发行版:

```powershell
wsl -l -v
```

期待:输出里有一行是 sshd 所在的发行版(前面带 `*` 的是默认发行版),第一列就是发行版名,例:

```
  NAME            STATE           VERSION
* Ubuntu-22.04    Running         2
```

名字是 `Ubuntu-22.04` 时,4.2 直接执行就行;不是时,按表4-2 改。

**表4-2　脚本里可能要改的地方(都在 `wsl_keepalive_setup.ps1` 开头的 `param`)**

| No. | 参数 | 默认值 | 管什么 | 什么时候改 | 怎么改 |
|---|---|---|---|---|---|
| 1 | `-Distro` | `Ubuntu-22.04` | 让哪个发行版一直开着 | 4.1 查到的名字不是 `Ubuntu-22.04` 时(例:`Ubuntu`、`Ubuntu-24.04`) | 执行时加参数 `-Distro <名字>`(见 4.2 第 2 条命令);或者把脚本里 `$Distro = 'Ubuntu-22.04'` 的值改掉 |
| 2 | `-TaskName` | `WSL-KeepAlive` | 任务计划程序里的任务名 | 一般不改。改了的话,取消时 `wsl_keepalive_remove.ps1` 也要加同样的 `-TaskName` | 执行时加参数 `-TaskName <名字>` |

名字要和 `wsl -l -v` 显示的**完全一样**(大小写、`-`、版本号)。写错时任务照样登记,但 WSL 起不来,脚本最后显示 NG。

### 4.2 设定(普通 PowerShell,不需要管理员,只做一次)

在脚本所在的文件夹执行(发行版是 `Ubuntu-22.04` 时用第 1 条,不是时用第 2 条):

```powershell
pwsh -ExecutionPolicy Bypass -File .\wsl_keepalive_setup.ps1
pwsh -ExecutionPolicy Bypass -File .\wsl_keepalive_setup.ps1 -Distro Ubuntu-24.04
```

期待:最后一行显示 `OK: WSL is kept running.`。显示 `NG: task or WSL is not running.` 时,任务或 WSL 没在运行,先看 4.1 的发行版名对不对。

登记会一直保存,以后每次登录 Windows 自动执行,**不用再执行**。下面几种情况要再执行一次 4.2:

**表4-3　要再执行 4.2 的情况**

| No. | 情况 | 原因 |
|---|---|---|
| 1 | 执行了 `wsl --shutdown`,或 WSL 被关掉 | `sleep infinity` 跟着结束,要到下次登录才自动再启动。不再执行的话,WSL 照样能用,但空闲时又会自动关机 |
| 2 | 换了电脑、重装了 Windows | 登记存在这台 Windows 里,新环境里没有 |
| 3 | 发行版名变了 | 任务里写死了发行版名,要用新名字加 `-Distro` 再执行 |

### 4.3 确认

重启 Windows,登录后过一会儿执行:

```powershell
wsl -l -v
```

期待:4.1 那个发行版的 STATE 是 `Running`。不开任何 WSL 终端,过几分钟再看还是 `Running`,就说明保活生效。

### 4.4 取消

```powershell
pwsh -ExecutionPolicy Bypass -File .\wsl_keepalive_remove.ps1
```

期待:显示 `Task 'WSL-KeepAlive' removed.`(没登记过时显示 `not found. Nothing to do.`)。

<details>
<summary>详细(需要时再看)</summary>

- 必须用**用户账户**跑,不能用 SYSTEM:SYSTEM 账户调 `wsl.exe` 会报 `WSL_E_LOCAL_SYSTEM_NOT_SUPPORTED`。脚本用的是执行它的那个用户。
- `conhost.exe --headless`:不出窗口地启动 `wsl.exe`。直接执行 `wsl.exe` 会留一个黑色窗口,关掉它保活就失效。
- `-ExecutionTimeLimit ([TimeSpan]::Zero)`:取消计划任务默认的「运行 72 小时后强制结束」。
- 电池相关两个选项:笔记本拔电源时也不停止任务。
- `-MultipleInstances IgnoreNew`:已经在跑时不再启动第二个,`sleep infinity` 不会越开越多。
- 取消时只删任务的话,正在跑的 `sleep infinity` 还在,WSL 仍一直开着;所以 `wsl_keepalive_remove.ps1` 会把它结束掉。
- `-ExecutionPolicy Bypass`:只对这一次执行放开脚本限制,不改系统设定;从网上下载的 ps1 也能直接执行。

</details>

## 5. 删除

```powershell
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0
Remove-NetFirewallRule -DisplayName 'WSL SSH 2222'

# 如果做了第 4 节(在脚本所在的文件夹执行)
pwsh -ExecutionPolicy Bypass -File .\wsl_keepalive_remove.ps1
```
