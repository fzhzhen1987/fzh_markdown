# docker容器相关操作

- 使用容器端口的准备工作(确认机器是否已经打开80端口)  
	```shell
	sudo pacman -S net-tools
	netstat -tunlp
	```

- 查看正在运行的容器  
	```shell
	sudo docker ps
	ps -ef|grep docker
	```

- 查看所有运行过的容器记录  
`sudo docker ps -a`

- 创建+启动(如果镜像本地不存在,则下载该镜像)  
***容器内的进程必须处于前台运行状态,否则容器直接退出***  
`docker run`

- 创建并启动nginx容器
	```shell
	# -d :后台运行(docker ps 查看相关信息)
	# -p 80:80 :-p 宿主机端口:容器端口 当访问宿主机的端口等于访问了容器的端口
	#docker run 返回容器id
	> docker run -d -p 80:80 nginx
	e41cfa98293869d22caf5dc3ba32ae7acd6e7ec753774238f2ea6589f14338cb
	
	#交互式运行镜像 -it 开启交互式终端, --name 设定容器名字, --rm 容器退出时删除此容器
	> docker run -it --rm --name ubuntu_test ubuntu bash
	```

- 创建启动容器,且进入容器内  
`docker run -it ubuntu bash`

- 开启一个容器,并运行某个程序  
`docker run ubuntu ping baidu.com`

- 运⾏⼀个活着的容器,-d :让容器在后台跑着 (针对宿主机⽽⾔).返回容器id  
`docker run -d ubuntu ping baidu.com`

- 丰富 docker 运行参数  
-d :后台运行  
--rm :容器挂掉后自动被删除  
--name :给容器起个名字  
`docker run -d --rm --name ubuntu_nvim ubuntu ping baidu.com`

- 运行某个容器  
	```shell
	docker start e41cfa982938
	docker start -i e41cfa982938
	```

- 停止某个容器  
`docker stop e41cfa982938`

- 进入到正在运行的容器内  
`docker exec -it ubuntu_test bash`

- 删除容器记录(从 docker ps -a 得到的结果中)  
`sudo docker rm [CONTAINER ID]` 

- 批量删除容器(打印命令的执行结果)  
	```shell
	sudo docker rm `docker ps -aq`
	```

- 查看容器日志,刷新日志  
	```shell
	docker logs [CONTAINER ID] -f
	docker logs [CONTAINER ID] | tail -5
	```

- 查看容器的详细信息,⽤于⾼级的调试  
`docker container inspect [CONTAINER ID]`

- 容器的端⼝映射  
后台运⾏nginx容器，且起个名字，且端⼝映射宿主机的85端⼝，访问到容器内的80端⼝  
`docker run -d --name nginx_test -p 85:80 nginx`

- 查看端口转发情况  
`docker port [CONTAINER ID]`

- 容器的提交(对容器做出修改后)  
`docker commit [CONTAINER ID] 新的镜像名`

