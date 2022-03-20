# docker安装以及配置
基于manjaro-raspi4

- [一.安装docker](#1)
- [二.修改镜像配置文件](#2)
- [三.重启docker服务](#3)

--------
<h4 id="1">[一.安装docker]</h>

- archlinux系统上安装docker  
	```shell
	sudo pacman -Syu
	sudo pacman -S docker
	
	sudo systemctl start docker.service
	sudo systemctl status docker.service
	
	sudo systemctl enable docker.service
	
	sudo docker version
	
	将fzh用户加入到docker组
	sudo usermod -aG docker $(whoami)
	```


<h4 id="2">[二.修改镜像配置文件]</h>

- 假如使用国内镜像,编辑文件 /etc/docker/daemon.json  
	```shell
	{
	    "registry-mirrors": [
	        "https://registry.docker-cn.com"
	        "https://docker.mirrors.ustc.edu.cn"
	    ]
	}
	```

<h4 id="3">[三.重启docker服务]</h>

- 编辑配置镜像文件后重启docker服务
	```shell
	sudo systemctl daemon-reload
	sudo systemctl restart docker
	```

