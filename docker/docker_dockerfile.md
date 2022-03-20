# dockerfile写法

dockerfile实例
```shell
FROM ubuntu:16.04

RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y libc6:i386 libncurses5:i386 libstdc++6:i386
RUN apt-get install -y zsh
RUN apt-get install -y zlib1g:i386
RUN apt-get install -y tofrodos
RUN apt-get install -y libncurses-dev patch device-tree-compiler
RUN apt-get install -y make gcc git bc flex bison libssl-dev
RUN apt-get install -y m4 m4-doc
RUN apt-get install -y g++ wget cpio unzip bzip2
RUN apt-get install -y rsync kmod
RUN apt install -y python

CMD ["/bin/zsh"]
```

- 制作镜像使用的基础版本  
`FROM ubuntu:16.04`

- 脚本中执行shell命令  
`RUN apt-get install -y zsh`

- 指定容器启动时执行的命令  
`CMD ["参数1","参数2","参数3"]`  
`CMD ["/bin/zsh"]`

- 添加宿主机文件到容器内并自动解压  
`ADD 宿主机位置1 宿主机位置2 容器内位置`

- 添加宿主机文件到容器内不解压  
`COPY 宿主机位置1 宿主机位置2 容器内位置`

- 目录切换  
`WORKDIR`

- 设置存储卷,将容器内的存储卷映射到宿主机  
`VOLUME`

- 容器内暴露一个端口为了实现同宿主机通信  
`EXPORT`

- dockerfile写好后,创建镜像  
`docker build .`




