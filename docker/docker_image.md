# docker镜像相关操作

- 查看docker版本  
`sudo docker version`

- 搜索网络上的镜像:以nginx为例  
`sudo docker search nginx`

- 拉取镜像  
`sudo docker pull nginx`

- 列出本地镜像列表  
`sudo docker images`

- 删除镜像(被删除的镜像不能存在容器的依赖记录 docker ps -a)  
	```shell
	sudo docker rm [CONTAINER ID]
	sudo docker rmi [IMAGE ID]
	```

- 批量删除镜像(打印命令的执行结果)  
	```shell
	sudo docker rmi `docker images -aq`
	```

- 修改镜像名  
`docker tag IMAGE_ID 你想要的名字`

- 查看镜像保存路径  
	```shell
	> docker info |grep Root
	Docker Root Dir: /var/lib/docker
	```

- 存放IMAGE id路径(记录镜像和容器的配置关系)  
`/var/lib/docker/image/overlay2/imagedb/content/sha256`

- 导出镜像  
`docker image save ubuntu:[TAG号] > ~/dockers/ubuntu_changed.tgz`

- 导入镜像  
`docker image load -i ~/dockers/ubuntu_changed.tgz`

- 查看某个镜像详细信息  
`docker image inspect [IMAGE ID]`
