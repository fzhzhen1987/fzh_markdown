# Manjaro安装

- [一.制作镜像工具:Ventoy](#1)
- [二.安装Manjaro系统](#2)

---
<h4 id="1">[一.制作镜像工具:Ventoy]</h>

[Ventoy github](https://github.com/ventoy/Ventoy)  
[Linux 系统图形界面使用方法](https://www.ventoy.net/cn/doc_linux_gui.html)  

- 格式化U盘  
	```shell
	./VentoyGUI.x86_64 --qt5
	
	配置选项:选择GTP
	```
- 将镜像拷贝到格式化好的U盘,调整好Bios就可以开始安装  

<h4 id="2">[二.安装Manjaro系统]</h>

- **分区的注意事项:选择 <kbd>手动分区</kbd>**  

- 1.开启sshd  
`sudo systemctl start sshd`

- 2.修改组号,方便添加fzh用户和组  
`groupmod -g 1347 feng`

- 3.更换源  
	```shell
	查看连接速度
	sudo pacman-mirrors -g
	
	sudo pacman-mirrors -i -c China -m rank
	```

- 4.安装软件聚集  

