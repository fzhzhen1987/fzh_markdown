# DevOps

- [1.安装gitlab](#1)  
- [2.](#2)  


<h4 id="1">[1.安装gitlab]</h>  

1. 前提:`安装了docker和docker-compose`  
	```shell
	docker version
	docker-compose version
	```

1. 查找拉取gitlab镜像  
	```shell
	docker search gitlab
	docker pull gitlab/gitlab-ce:latest
	docker images
	```

1. 添加docker-compose.yml内容  
	```
	mkdir /usr/local/docker/gitlab_docker
	cd /usr/local/docker/gitlab_docker
	nv docker-compose.yml
	```

	[docker-compose.yml](docker-compose.yml)  

1. 运行docker-compose: `docker-compose up -d`  

1. 进入容器内部确定root密码  
	```shell
	docker exec -it gitlab bash
	cat /etc/gitlab/initial_root_password
	```

	<details>
	<summary>获得gitlab root初始化密码</summary>
	<img src= initial_root_password.png />
	</details>

	<details>
	<summary>修改gitlab root密码</summary>
	<img src= change_pw.png />
	</details>

