# 在raspi4上安装archlinux

- [一.制作archlinux系统MircoSD](#1)
- [二.将mircoSD插入raspi4,使用串口连接](#2)
- [三.wifi网络配置](#3)
- [四.VNC远程桌面登录](#4)
- [五.key更新](#5)

---
<h4 id="1">[一.制作archlinux系统MircoSD]</h>

- 确定microSD卡的分区  
<font color=red>sudo fdisk -l</font>

| Device         | Boot |     Start |       End |   Sectors |   Size | Id |            Type |
|----------------|------|----------:|----------:|----------:|-------:|---:|----------------:|
| /dev/mmcblk1p1 | *    |      8192 |    524287 |    516096 |   252M |  c | W95 FAT32 (LBA) |
| /dev/mmcblk1p2 |      |    524288 | 168296447 | 167772160 |    80G | 83 |           Linux |
| /dev/mmcblk1p3 |      | 168296448 | 384503807 | 216207360 | 103.1G |  7 | HPFS/NTFS/exFAT |

- [利用脚本生成分区 part_disk.sh(参考使用)](part_disk.sh)  

- 格式化p1和p2分区  
	```shell
	sudo mkfs.vfat /dev/sda1
	sudo mkfs.ext4 /dev/sda2
	```

- 建立文件夹<font color=red>root</font>和<font color=red>boot</font>,并分别挂载分区  
	```shell
	mkdir boot
	mkdir root
	sudo mount /dev/sda1 boot
	sudo mount /dev/sda2 root
	```

- 切换到root操作(下载镜像,并展开文件系统到root)  
	```shell
	su
	wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
	bsdtar -xpf ArchLinuxARM-rpi-aarch64-latest.tar.gz -C root
	sync
	```

- 修改etc,使用我的etc  
	```shell
	cd root/
	mv etc etc_old
	git clone https://github.com/fzhzhen1987/etc.git
	cp -r etc_old/* etc
	rm -rf etc_old
	```

	 - 对etc做一些微调  
		```shell
		cd etc
		git checkout locale.gen
		NEW_HOSTNAME=arch-raspi4
		sed -i 's/alarm/'$NEW_HOSTNAME'/g' hostname
		echo "127.0.0.1      ${NEW_HOSTNAME}.localdomain  $NEW_HOSTNAME" >> /etc/hosts
		```

- 将root/boot拷贝到boot分区
	```shell
	cd ../..
	mv root/boot/* boot
	```

- 修改fstab,启动时挂载分区,建立share和work_fzh文件夹  
	```shell
	mkdir root/home/share root/home/work_fzh
	sed -i 's/mmcblk0/mmcblk1/g' root/etc/fstab
	echo "/dev/mmcblk1p3  /home/share  exfat  defaults,,iocharset=utf8,umask=000  0  1">>root/etc/fstab
	umount root boot
	```

<h4 id="2"><font color=red>[二.将mircoSD插入raspi4,使用串口连接]</font></h>

- 登陆用账号密码均为<font color=red>root</font>  

- 给root添加密码,删除alarm用户,并添加fzh用户  
	```shell
	passwd
	userdel -r alarm
	groupadd -g 1000 fzh
	useradd -u 2018 -m -g fzh -s /bin/bash fzh
	passwd fzh
	gpasswd -a fzh wheel
	
	修改组号
	groupmod -g 2000 fzh
	```

- <font color=red>重启ssh使用fzh账户登陆,网线也许需要</font>

- 更新系统并安装必要软件  
	```shell
	pacman-key --init
	pacman-key --populate
	pacman -Syu
	pacman -Syu sudo base-devel uboot-tools neovim tmux tig git lazygit ripgrep zsh bear fd ccls wget samba iw dialog networkmanager netctl ranger fzf ttf-dejavu wqy-microhei wqy-zenhei xorg-mkfontscale python-pynvim global ctags htop the_silver_searcher colordiff python3 python3-pip ntp w3m git-delta perl-module-build
	```

- 构建fzh目录  
	```shell
	chown fzh:fzh /home/fzh/ -R
	
	cd /home/fzh/
	rm -rf .*
	
	git clone https://github.com/fzhzhen1987/fzh.git
	cp -r fzh/.* .
	cp -r fzh/* .
	
	cd .config
	git clone https://github.com/fzhzhen1987/nvim.git
	
	git clone https://github.com/cdump/ranger-devicons2 ~/.config/ranger/plugins/devicons2
	sed -i 's/default_linemode devicons/default_linemode devicons2/g' ranger/rc.conf 
	
	cd ..
	cp memo/install.sh .
	chmod +x install.sh
	./install.sh
	
	git checkout .zshrc
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
	```

	- <font color=red>更改/home/work_fzh所属</font>  
		```shell
		cd /home/
		sudo chown fzh:fzh work_fzh -R
		```

- 修改fzh登陆shell  
	```shell
	less /etc/passwd
	sudo usermod -s /bin/zsh fzh
	```

- nvim相关配置  
	```shell
	git config --global core.editor nvim
	python3 -m pip install --upgrade pip
	pip3 install --user --upgrade pynvim
	pip3 install --user --upgrade neovim
	pip3 install --user --upgrade pygments
	cp /usr/share/gtags/gtags.conf ~/.gtags.conf
	
	cd /home/fzh/memo/
	git clone https://aur.archlinux.org/vim-markdown-preview-git.git
	cd vim-markdown-preview-git
	makepkg -si
	
	cd /home/fzh/memo/
	git clone https://aur.archlinux.org/vim-instant-markdown.git
	cd vim-instant-markdown
	makepkg -si
	```

- 修改lazygit的page为delta  
	```shell
	cd /home/fzh/memo/
	git clone https://aur.archlinux.org/git-delta-bin.git
	cd git-delta-bin
	makepkg -si
	makepkg --clean -f
	```

- yay相关  
	```shell
	cd /home/fzh/memo/
	git clone https://aur.archlinux.org/yay.git
	cd yay
	makepkg -si
	yay -S ccat yank python-ueberzug-git
	```

- 时间同步  
	```shell
	sudo ntpdate cn.ntp.org.cn
	sudo timedatectl list-timezones
	sudo timedatectl set-timezone Asia/Tokyo
	sudo timedatectl set-ntp true
	sudo hwclock
	```

- 生成字体  
	```shell
	sudo pacman -S xorg-mkfontscale
	git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
	cd nerd-fonts
	./install.sh SourceCodePro
	sudo mkfontscale
	sudo mkfontdir
	sudo fc-cache -fv
	```

<h4 id="3">[三.wifi网络配置]</h>

- 安装网络必要APP  
	```shell
	sudo systemctl status NetworkManager
	sudo systemctl start NetworkManager
	sudo systemctl enable NetworkManager
	```

- 扫描可用的wifi节点  
`sudo nmcli d wifi list`

- 连接wifi节点  
	```shell
	sudo nmcli d wifi c 416 password 28267598 ifname wlan0
	sudo nv NetworkManager/system-connections/416_5G.nmconnection NetworkManager/system-connections/416.nmconnection
	```

- 断开连接  
`nmcli c d 416`

- 重新载入配置文件  
`nmcli c reload`

- 启动连接  
`nmcli c up 416`

- 启动samba  
	```shell
	smbpasswd -a fzh
	systemctl enable smb.service nmb.service
	```


<h4 id="4">[四.VNC远程桌面登录]</h>

- 安装以及配置  
	```shell
	sudo pacman -S firefox firefox-i18n-zh-cn terminator xorg xorg-xinput lightdm fcitx5-im fcitx5-chinese-addons fcitx5-pinyin-zhwiki tigervnc xfce4 xfce4-goodies
	vncpasswd
	sudo systemctl start vncserver@:1
	
	
	配置文件
	/etc/tigervnc/vncserver.users 中添加
	:0=root
	:1=fzh
	
	~/.vnc/config 中添加
	session=xfce
	geometry=1920x1080
	```

<h4 id="5">[五.key更新]</h>

- key正常更新流程
	```shell
	pacman -Syy
	pacman -S archlinux-keyring
	pacman-key --populate archlinux
	pacman-key --refresh-keys
	```

- archlinuxcn的key更新
	```shell
	pacman -Syy
	pacman -S archlinux-keyring
	pacman -Sy archlinuxcn-keyring
	pacman-key --refresh-keys
	```

- archlinuxcn-keyring 报错"无法本地签名"
	```shell
	pacman -Syu haveged
	systemctl start haveged
	systemctl enable haveged
	
	rm -rf /etc/pacman.d/gnupg
	pacman-key --init
	pacman-key --populate archlinux
	pacman-key --populate archlinuxcn
	```

