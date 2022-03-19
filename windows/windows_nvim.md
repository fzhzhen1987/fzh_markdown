# powershell和nvim以及wsl2相关配置

- [1.下载powershell](#1)  
- [2.添加powershell配置文件](#2)  


<h4 id="1">[1.下载powershell]</h>  

> 下载最新**powershell-x.x.x-win-x64.msi**  
> 查看powershell版本  
> `$host`

- [powershell下载地址](https://github.com/PowerShell/PowerShell)  

<h4 id="2">[2.添加powershell配置文件]</h>  

> windows terminal 配置文件位置(按键映射以及外观设置)
> `C:\Users\fzh-3070ti\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
> ![](powershell/pic_1.png)
>
> windows terminal设置为中文
> ![](powershell/pic_2.png)
>
> 将powershell添加到windows terminal
> ![](powershell/pic_3.png)

## 一.安装scoop

### 1.修改scoop安装的环境变量
```shell
$env:SCOOP='c:\Scoop'
[Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
```

### 2.安装scoop
```shell
iwr -useb get.scoop.sh | iex
```

### 3.安装一些命令
```shell
scoop install ripgrep
scoop install git
scoop bucket add versions
scoop update git
scoop bucket add extras
scoop install posh-git
scoop install https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/oh-my-posh.json
scoop update oh-my-posh
scoop install lazygit
scoop install graphviz
scoop bucket add java
scoop install openjdk
scoop install neovim-nightly
scoop install delta
scoop install mingw fd file lf fzf PSFzf
scoop install global ctags
```

## 二.powershell安装emacs键位

### 在本terminal更改为emacs键位,在terminal输入
```shell
Install-Module -Name PowerShellGet -Force
Install-Module PSReadLine
Set-PSReadLineOption -EditMode Emacs

列出按键
Get-PSReadLineKeyHandler
```

### 生成配置文件,在terminal输入
```shell
if (!(Test-Path -Path $PROFILE )) { New-Item -Type File -Path $PROFILE -Force }

显示配置文件所在位置
echo $PROFILE

C:\文档\PowerShell\Microsoft.PowerShell_profile.ps1
```

### Microsoft.PowerShell_profile.ps1文件内容
先设定环境变量(废弃)
```shell
POSH_THEMES_PATH
%SCOOP%\apps\oh-my-posh\current\themes
```
编辑Microsoft.PowerShell_profile.ps1
```shell
Import-Module PSReadLine
Import-Module posh-git
Set-PSReadLineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-Alias -Name lg -Value lazygit
setx POSH_THEMES_PATH "%LOCALAPPDATA%\Programs\oh-my-posh\themes"
oh-my-posh --init --shell pwsh --config "$env:POSH_THEMES_PATH\ys.omp.json" | Invoke-Expression

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
setx FZF_DEFAULT_OPTS "--no-mouse"

function ra {
    $tempFile = [System.IO.Path]::GetTempFileName()
    & lf.exe -last-dir-path $tempFile
    if (Test-Path -LiteralPath $tempFile) {
        $lastDir = Get-Content -LiteralPath $tempFile
        Remove-Item -LiteralPath $tempFile
        if (Test-Path -LiteralPath $lastDir) {
            $currentLocation = Get-Location
            if ($lastDir -ne $currentLocation) {
                Set-Location -LiteralPath $lastDir
            }
        }
    }
}
```
### 实现右键菜单
```shell
git clone https://github.com/LittleNewton/Open_Windows_Terminal_Here.git
cd Open_Windows_Terminal_Here/src
.\install.ps1 mini
```

### lazygit配置文件位置
```shell
C:\Users\fzh-3070ti\AppData\Roaming\lazygit
```

### tig配置文件位置(%USERPROFILE%)
```shell
C:\Users\fzh-3070ti\
```

### lf配置文件位置
```shell
C:\Users\fzh-3070ti\AppData\Local\lf
```

### 查看环境变量
```shell
Get-ChildItem env:
```

### 查看命令位置,比如lf
```shell
Get-Command lf
```

## 三.安装nerd字体

### 1.通过网址下载,打开以下网址
```shell
https://www.nerdfonts.com/font-downloads

选择喜欢的字体
Sauce Code Pro Semibold Nerd Font
Sauce Code Pro Semibold Nerd Font Complete Windows Compatible.ttf
```
## 四.nvim配置

### 1.nvim配置文件位置
```shell
C:\Users\fzh-3070ti\AppData\Local\nvim
```

### 2.其他必须操作
```shell
scoop install nvm
nvm list available
nvm install 16.13.1 注意安装LTS列的最新
nvm use 16.13.1

修改nvm环境变量(废弃)
NVM_SYMLINK
c:\Scoop\persist\nvm\nodejs\v16.15.0

Path(废弃)
C:\Scoop\apps\nvm\current\nodejs\v16.15.0


scoop search python
scoop install python

python3.exe -m pip install --upgrade pip
当以上命令报错时,使用以下命令
python -m pip install -U pip --user
并添加pip环境变量


pip3 install --user --upgrade pynvim
pip3 install --user --upgrade neovim
pip3 install --user --upgrade pygments
```

### 3.gtags配置文件位置
```shell
C:\Users\用户名\.gtags.conf
```

## 五.WSL2使用manjaro

### 1.安装WSL2:使用管理员身份打开terminal
```shell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

以上两条命令执行后,需要重启电脑

下载Linux内核更新包:网址如下
https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi

将WSL2设为默认版本
wsl --set-default-version 2
```

### 2.安装manjaro 或者Ubuntu22.04
```shell
scoop install manjarowsl

wsl --install -d Ubuntu-22.04
wsl --update

实体硬盘路径
C:\Scoop\persist\manjarowsl\data\ext4.vhdx

如果需要修改硬盘分配空间大小(不能小于256G,例子设为512G)
diskpart
DISKPART> Select vdisk file="C:\Scoop\persist\manjarowsl\data\ext4.vhdx"
DISKPART> detail vdisk
DISKPART> expand vdisk maximum=512000
DISKPART> exit

缩小WSL2 VHDX文件大小(没试过)
进入到WSL2中,运行zerofree将ext4文件系统内已经不用的块填零,
但zerofree不能运行在已经挂载为rw的文件系统上.
那就把文件系统挂载为readonly就行了.

wsl2> mount /dev/sda -o remount,ro
wsl2> zerofree /dev/sda

wsl --shutdown

diskpart
DISKPART> Select vdisk file="C:\Scoop\persist\manjarowsl\data\ext4.vhdx"
DISKPART> compact vdisk
DISKPART> exit
```

### 3.在terminal中新建manjaro配置文件.如图
![](powershell/pic_4.png)
```shell
配置文件头像设定
ms-appx:///ProfileIcons/{9acb9455-ca41-5af7-950f-6bca1bc9722f}.png
```

### 4.启动manjaro
```shell
首先确定是否在WSL2运行
wsl -l -v

新建用户
useradd -u 2018 -m -g fzh -G wheel -s /bin/bash fzh
passwd fzh
echo "%wheel ALL=(ALL) ALL" >/etc/sudoers.d/wheel
exit

WSL2 manjaro默认启动用户设定
Manjaro.exe config --default-user fzh
```

### 5.manjaro内部设定
```shell
sudo pacman-mirrors --country japan
sudo pacman -Syu
```

## 六.安装 Alacritty 终端

### 1.使用 scoop 安装 Alacritty
```shell
# 添加 extras bucket（如果还没添加）
scoop bucket add extras

# 安装 Alacritty
scoop install extras/alacritty
scoop install vcredist2022

reg import "C:\Scoop\apps\alacritty\current\install-context.reg"
```

### 2.Alacritty 配置文件位置
```shell

%APPDATA%\alacritty\alacritty.toml
或
C:\Users\用户名\AppData\Roaming\alacritty\alacritty.toml

New-Item -ItemType Directory -Force -Path "$env:APPDATA\alacritty"
New-Item -ItemType File -Force -Path "$env:APPDATA\alacritty\alacritty.toml"
notepad "$env:APPDATA\alacritty\alacritty.toml"
```

### 3.基础配置示例（alacritty.toml）
```toml
# 窗口设置
[window]
opacity = 0.95                    # 透明度
padding = { x = 5, y = 5 }        # 内边距
decorations = "Full"              # 窗口装饰: Full/None/Transparent/Buttonless

# 字体设置
[font]
size = 11.0

[font.normal]
family = "SauceCodePro Nerd Font"   # 使用已安装的 Nerd Font
style = "Regular"

[font.bold]
family = "SauceCodePro Nerd Font"
style = "Bold"

[font.italic]
family = "SauceCodePro Nerd Font"
style = "Italic"

# 颜色主题（One Dark）
[colors.primary]
background = "#282c34"
foreground = "#abb2bf"

[colors.normal]
black   = "#1e2127"
red     = "#e06c75"
green   = "#98c379"
yellow  = "#d19a66"
blue    = "#61afef"
magenta = "#c678dd"
cyan    = "#56b6c2"
white   = "#abb2bf"

[colors.bright]
black   = "#5c6370"
red     = "#e06c75"
green   = "#98c379"
yellow  = "#d19a66"
blue    = "#61afef"
magenta = "#c678dd"
cyan    = "#56b6c2"
white   = "#ffffff"

# 选择设置
[selection]
save_to_clipboard = true          # 鼠标选中自动复制到剪贴板

# 鼠标绑定
[[mouse.bindings]]
mouse = "Right"
action = "Paste"                  # 鼠标右键粘贴

# Shell 设置（0.13.0+ 使用 terminal.shell）
[terminal.shell]
program = "pwsh.exe"              # 使用 PowerShell
# 如果要使用 WSL2
# program = "wsl.exe"
# args = ["~"]

# 光标设置
[cursor.style]
shape = "Block"                   # Block/Underline/Beam
blinking = "Off"                  # Off/On/Always

# 键盘映射示例
[[keyboard.bindings]]
key = "V"
mods = "Control|Shift"
action = "Paste"

[[keyboard.bindings]]
key = "C"
mods = "Control|Shift"
action = "Copy"

[[keyboard.bindings]]
key = "N"
mods = "Control|Shift"
action = "SpawnNewInstance"
```

### 4.将 Alacritty 设为默认终端
```shell
# 方法1: 在 Windows 设置中
# 设置 -> 隐私和安全 -> 开发者选项 -> 终端 -> 选择 Alacritty

# 方法2: 创建快捷方式
# 右键 Alacritty -> 发送到 -> 桌面快捷方式
# 可以设置启动参数，例如:
# "C:\Scoop\apps\alacritty\current\alacritty.exe" --working-directory "C:\Projects"
```

### 5.与 WSL2 集成使用
```toml
# 在 alacritty.toml 中配置直接启动 WSL2
[terminal.shell]
program = "wsl.exe"
args = ["~"]

# 或者配置特定的 WSL 发行版
# program = "wsl.exe"
# args = ["-d", "Manjaro", "~"]
```

### 6.常用快捷键（默认）
```shell
Ctrl+Shift+C    # 复制
Ctrl+Shift+V    # 粘贴
Ctrl+Shift+N    # 新建窗口
Ctrl+Plus       # 放大字体
Ctrl+Minus      # 缩小字体
Ctrl+0          # 重置字体大小
```

## 七.为拯救者安装工具箱

```shell
scoop install extras/lenovolegiontoolkit
```

