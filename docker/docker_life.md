# docker生命周期
### 生命周期将围绕下面的图为核心讲解
![docker生命周期](pic/pic_1.jpg)

## 一.dockerfile
```text
用于构建docker image的脚本.

#构建dockerfile生成的镜像images
docker build .
```

## 二.Images
```text
#查看本地镜像文件
docker images

#将本地docker推送到网络
docker push

#从网络拉取镜像
docker pull 镜像名

#本地导出镜像为压缩文件
docker save

#本地导入镜像
docker load


#运行镜像,生成一个容器container
docker run 镜像名
```

## 三.Containers
```text
#某容器停止运行
docker stop 容器id名

#某容器开始运行
docker start 容器id名

#某容器再启动
docker restart 容器id名

#对容器做出修改后,生成一个新的镜像
docker commit 容器id名
```

