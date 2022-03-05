# 检查memory leak

- [1.宏定义截获malloc/free](#1)  
- [2.](#2)  
- [3.](#3)  

##### 内存泄漏的起因:  
```shell
调用malloc,没有调用free.
调用new,没有调用delete.
```

<h4 id="1">[1.宏定义截获malloc/free]</h>  

[memoryleak_ver1.c](memoryleak_ver1.c)  

- 编译:`gcc -o memoryleak memoryleak.c`  
- 核心思想:**重载malloc,取代原本的malloc**  

[memoryleak_ver2.c](memoryleak_ver2.c)  
[memoryleak_ver3.c](memoryleak_ver3.c)  
- 关于内存泄漏的检查  
	```shell
	1. 有没有内存泄漏
	2. 有内存泄漏,需要定位约精准
	3. 输出到文件
	```

[memoryleak_ver4.c](memoryleak_ver4.c)  
- 改进创建文件,成对的删除,不成对(未释放)的保留.  
- 宏定义截获总结  
	```shell
	1. #define要放在拦截用自制函数之后
	2. malloc(5) = _malloc(5, __FILE__, __LINE__)
	3. memoryleak_ver4.c此方式适用于单文件
	```

[memoryleak_ver5.c](memoryleak_ver5.c)  

<details>
<summary>dlsym</summary>
<img src= dlsym.png />
</details>

- **dlopen打开软链接**:  
`在库文件中查找符号,如果库是一个符号链接,则dlopen()会打开只向链接目标的实际文件`  
- **实现hook的步骤**  
	1. 定义类型和变量  
		```c
		typedef void *(*malloc_t)(size_t size);
		typedef void (*free_t)(void *ptr);
		//定义两个函数指针类型定义,因此可以使用malloc_t定义变量

		malloc_t malloc_t = NULL;
		free_t free_t = NULL;
		```

	1. 获取代码段中**malloc**动态链接的地址,并将它赋值给自己制作的malloc_f函数  
		```c
		malloc_f = (malloc_t)dlsym(RTLD_NEXT, "malloc");
		```

	1. 编译:`gcc -o memoryleak memoryleak.c -ldl -g`  


- 对应segmentation fault:`把版本倒回去`  
	```c
	//调用自己写的malloc出现段错误,原因无限递归栈溢出
	//printf中也调用了malloc,然后自制的malloc又调用了printf,无限循环
	void *malloc(size_t size) {
		printf("malloc\n");	//printf中使用了malloc函数 --> size = 1024
	}
	
	//解决办法:添加递归终止条件
	```

[memoryleak_ver6.c](memoryleak_ver6.c)  
- __LINE__行号不能正确显示,需要显示malloc被调用地方的行号  
	```c
	使用编译器自带的函数:
	void *caller = __builtin_return_address(n);
	
	n = 0: 返回 上一级 被调用的位置,
	n = 1: 返回 上一级的上一级 被调用的位置
	```

- 如何分析__builtin_return_address(n)获得的数据  
	```shell
	得到泄漏地址:
	[+]0xaaaaada70cfc addr: 0xaaaaed7d46c0, size: 15
	
	分析地址:
	0xaaaaada70cfc 对应caller
	
	执行命令:
	addr2line -f -e memoryleak -a 0xaaaaada70cfc
	```

- dlsym比宏定义malloc的优点:`dlsym适合整个工程,宏定义malloc适合单文件`  


