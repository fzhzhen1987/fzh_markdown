# docker安装以及使用
基于manjaro-raspi4
## 一.安装docker以及配置


### 安装docker
```shell
sudo pacman -Syu
sudo pacman -S docker
sudo systemctl start docker.service
sudo systemctl status docker.service

sudo systemctl enable docker.service

sudo docker version

将fzh用户加入到docker组
sudo usermod -aG docker fzh
```

### 使用国内镜像,编辑文件 /etc/docker/daemon.json
```shell
{
    "registry-mirrors": [
        "https://registry.docker-cn.com"
        "https://docker.mirrors.ustc.edu.cn"
    ]
}
```

### 编辑配置文件后重启docker服务
```shell
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 搜索和拉取镜像(image)
```shell
#查看容器和镜像
sudo docker images
sudo docker images -a


#查看正在运行的容器和镜像
sudo docker ps
sudo docker ps -a    #查看所有的运行记录
ps -ef|grep docker

#删除容器记录(docker ps -a 得到的记录)
sudo docker rm [CONTAINER ID]

#删除镜像(被删除的镜像不能存在容器的依赖记录)
sudo docker rmi [IMAGE ID]/docker名

#批量删除(``打印命令的执行结果)
sudo docker rmi `docker images -aq`

#搜索镜像:以nginx为例
sudo docker search nginx

#拉取镜像
sudo docker pull nginx

#下载完成后,确认镜像
> sudo docker image ls
REPOSITORY   TAG       IMAGE ID       CREATED      SIZE
nginx        latest    4f6e44d5fceb   2 days ago   134MB
```

### 运行nginx镜像
```shell
确认机器是否已经打开80端口
sudo pacman -S net-tools
netstat -tunlp

运行镜像
# -d :后台运行
# -p 80:80 :-p 宿主机端口:容器端口 当访问宿主机的端口等于访问了容器的端口
#docker run 返回容器id
> docker run -d -p 80:80 nginx
e41cfa98293869d22caf5dc3ba32ae7acd6e7ec753774238f2ea6589f14338cb

查看正在运行的容器
> docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS                               NAMES
e41cfa982938   nginx     "/docker-entrypoint.…"   16 minutes ago   Up 16 minutes   0.0.0.0:80->80/tcp, :::80->80/tcp   focused_bhaskara

访问本机ip的80端口
192.168.11.254:80

停止docker
docker stop e41cfa982938

运行容器
docker start -i e41cfa982938

查看docker信息(非常重要)
docker info

#查看docker镜像的存储路径
> docker info |gerp Root
Docker Root Dir: /var/lib/docker

#存放IMAGE id号
/var/lib/docker/image/overlay2/imagedb/content/sha256
```


