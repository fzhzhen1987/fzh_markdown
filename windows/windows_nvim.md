# powershell和nvim以及wsl2相关配置

[**最新powershell**](https://github.com/PowerShell/PowerShell)  
下载最新**powershell-x.x.x-win-x64.msi**  
查看powershell版本
```shell
$host
```
更换为最新版本powershell  
Terminal默认打开终端为PowerShell,并修改为中文
```shell
C:\Users\fzhzh\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

![](powershell/pic_1.png)
![](powershell/pic_2.png)
![](powershell/pic_3.png)
--------

## 烦人的onedrive
```shell
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders

HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders
```

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
先设定环境变量
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
oh-my-posh --init --shell pwsh --config "$env:POSH_THEMES_PATH\ys.omp.json" | Invoke-Expression
```
### 实现右键菜单
```shell
git clone https://github.com/LittleNewton/Open_Windows_Terminal_Here.git
cd src
.\install.ps1 mini
```

### lazygit配置文件位置
```shell
C:\Users\fzhzh\AppData\Roaming\lazygit
```

### 查看环境变量
```shell
Get-ChildItem env:
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
C:\Users\fzh\AppData\Local\nvim
```

### 2.其他必须操作
```shell
scoop install nvm
nvm list available
nvm install 16.13.1 注意安装LTS列的最新
nvm use 16.13.1

修改nvm环境变量
NVM_SYMLINK
c:\Scoop\persist\nvm\nodejs\v16.15.0

Path
C:\Scoop\apps\nvm\current\nodejs\v16.15.0


scoop search python
scoop install python

python3.exe -m pip install --upgrade pip

pip3 install --user --upgrade pynvim
pip3 install --user --upgrade neovim
pip3 install --user --upgrade pygments
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

### 2.安装manjaro
```shell
scoop install manjarowsl

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

