# docker常用命令
















### 导入导出镜像
```shell
#导出镜像(对镜像做出修改后,导出)
docker image save ubuntu:[TAG号] > ~/dockers/ubuntu_changed.tgz

#导入镜像
docker image load -i ~/dockers/ubuntu_changed.tgz
```

### 查看某个镜像信息
```shell
docker image inspect [IMAGE ID]
```
--------
## Container相关命令
### 1.docker run
	创建+启动,如果镜像本地不存在,则下载该镜像  
***容器内的进程必须处于前台运行状态,否则容器直接退出***

```shell
#1. 错误示范: 此写法会产生多条容器记录,且容器内没有程序在运行,因此挂了
docker run ubuntu

#2. 运行容器,且进入容器内
docker run -it ubuntu bash

#3. 开启一个容器,并运行某个程序
docker run ubuntu ping baidu.com

#4. 运⾏⼀个活着的容器, docker ps可以看到的容器
# -d :让容器在后台跑着 (针对宿主机⽽⾔)
# 返回容器id
docker run -d ubuntu ping baidu.com

#5. 丰富 docker 运行参数
# -d :后台运行
# --rm :容器挂掉后自动被删除
# --name :给容器起个名字
docker run -d --rm --name ubuntu_nvim ubuntu ping baidu.com

#6. 查看容器日志,刷新日志
docker logs [CONTAINER ID] -f
docker logs [CONTAINER ID] | tail -5

#7. 进⼊正在运⾏的容器空间内
docker exec -it ubuntu bash

#8. 查看容器的详细信息,⽤于⾼级的调试
docker container inspect [CONTAINER ID]

#9. 容器的端⼝映射
#后台运⾏nginx容器，且起个名字，且端⼝映射宿主机的85端⼝，访问到容器内的80端⼝
docker run -d --name nginx_test -p 80:80 nginx

#9.1 查看端口转发情况
docker port [CONTAINER ID]

#10 容器的提交
docker commit [CONTAINER ID] 新的镜像名
```

