# docker 运行ubuntu镜像
**基于manjaro-raspi4**

## 查看host本机系统信息
```shell
> cat /etc/manjaro-arm-version
rpi4 - xfce - 21.12
```

## 查找关于ubuntu相关的docker
```shell
docker search ubuntu
```

## 拉取ubuntu镜像
```shell
> docker pull ubuntu
Using default tag: latest
latest: Pulling from library/ubuntu
57d0418fe9dc: Pull complete
Digest: sha256:bea6d19168bbfd6af8d77c2cc3c572114eb5d113e6f422573c93cb605a0e2ffb
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
```

## 查看下载的 ubuntu 镜像,并运行容器且进入容器内
```shell
> docker images
REPOSITORY   TAG       IMAGE ID       CREATED      SIZE
ubuntu       latest    e784f03641c9   3 days ago   65.6MB
nginx        latest    4f6e44d5fceb   3 days ago   134MB


#-i :交互式命令操作
#-t :开启一个终端
#bash :进入容器后执行的命令
> docker run -it e784f03641c9 bash

#--rm :容器退出时删除该容器
> docker run -it --rm ubuntu bash

#进入到某个版本的docker容器
> docker run -it --rm ubuntu:[TAG号] bash

#可以连接网络
docker run -it --name ubuntu_test -p 6789:22 ubuntu  bash
```

## 进入到正在运行的镜像内
```shell
> docker exec -it e784f03641c9 bash
```

## 确认是否进入 ubuntu 容器
```shell
> cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=20.04
DISTRIB_CODENAME=focal
DISTRIB_DESCRIPTION="Ubuntu 20.04.4 LTS"
```

## 退出 ubuntu 容器
```shell
exit
```

## 重新启动 ubuntu 容器
```shell
docker start -i ubuntu_test
```

