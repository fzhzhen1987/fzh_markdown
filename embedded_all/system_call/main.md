# 一. 关于syscalls.h中SYSCALL_DEFINEx的作用  
结论:  
使用define转换目的:  
参数统一改为long型来接收,再强转为int,也就是系统调用本来传下来的参数类型.  
由于64位的Linux有CVE-2009-2009漏洞  
```shell
The ABI in the Linux kernel 2.6.28 and earlier on s390, powerpc, sparc64, and mips 64-bit platforms
requires that a 32-bit argument in a 64-bit register was properly sign extended
when sent from a user-mode application,
but cannot verify this, which allows local users to cause a denial of service (crash) or possibly gain
privileges via a crafted system call.
```
含义为:用户空间程序将系统调用中32位参数存放在64位寄存器中要做到正确的符号扩展,但是用户空间程序却不能保证做到这点.  
这样就会可以通过向有漏洞的系统调用传送特制参数便可以导致系统崩溃或获得权限提升.  
具体分析如下  

--------

## 以linux/net/socket.c 为例子分析宏展开(linux kernel 4.9)
例子代码以及相关内核文件.  
另外补充:可以在 *linux/kernel/sys.c* 自己添加新系统调用
```c
linux/net/socket.c
SYSCALL_DEFINE3(socket, int, family, int, type, int, protocol)

linux/include/linux/syscalls.h
linux/include/asm-generic/unistd.h
linux/kernel/sys.c
```

## include/linux/syscalls.h中的define 宏定义
```c
#define __MAP0(m,...)
#define __MAP1(m,t,a) m(t,a)
#define __MAP2(m,t,a,...) m(t,a), __MAP1(m,__VA_ARGS__)
#define __MAP3(m,t,a,...) m(t,a), __MAP2(m,__VA_ARGS__)
#define __MAP4(m,t,a,...) m(t,a), __MAP3(m,__VA_ARGS__)
#define __MAP5(m,t,a,...) m(t,a), __MAP4(m,__VA_ARGS__)
#define __MAP6(m,t,a,...) m(t,a), __MAP5(m,__VA_ARGS__)
#define __MAP(n,...) __MAP##n(__VA_ARGS__)

#define __SC_DECL(t, a)	t a
#define __SC_LONG(t, a) __typeof(__builtin_choose_expr(__TYPE_IS_LL(t), 0LL, 0L)) a
#define __SC_CAST(t, a)	(t) a
#define __SC_ARGS(t, a)	a
#define __SC_TEST(t, a) (void)BUILD_BUG_ON_ZERO(!__TYPE_IS_LL(t) && sizeof(t) > sizeof(long))
#define __TYPE_IS_LL(t) (__same_type((t)0, 0LL) || __same_type((t)0, 0ULL))


#define SYSCALL_DEFINE1(name, ...) SYSCALL_DEFINEx(1, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE2(name, ...) SYSCALL_DEFINEx(2, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE3(name, ...) SYSCALL_DEFINEx(3, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE4(name, ...) SYSCALL_DEFINEx(4, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE5(name, ...) SYSCALL_DEFINEx(5, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE6(name, ...) SYSCALL_DEFINEx(6, _##name, __VA_ARGS__)

#define SYSCALL_DEFINEx(x, sname, ...)				\
	SYSCALL_METADATA(sname, x, __VA_ARGS__)			\  此行可以无视
	__SYSCALL_DEFINEx(x, sname, __VA_ARGS__)

#define __PROTECT(...) asmlinkage_protect(__VA_ARGS__)
#define __SYSCALL_DEFINEx(x, name, ...)					\
	asmlinkage long sys##name(__MAP(x,__SC_DECL,__VA_ARGS__))	\
		__attribute__((alias(__stringify(SyS##name))));		\
	static inline long SYSC##name(__MAP(x,__SC_DECL,__VA_ARGS__));	\
	asmlinkage long SyS##name(__MAP(x,__SC_LONG,__VA_ARGS__));	\
	asmlinkage long SyS##name(__MAP(x,__SC_LONG,__VA_ARGS__))	\
	{								\
		long ret = SYSC##name(__MAP(x,__SC_CAST,__VA_ARGS__));	\
		__MAP(x,__SC_TEST,__VA_ARGS__);				\
		__PROTECT(x, ret,__MAP(x,__SC_ARGS,__VA_ARGS__));	\
		return ret;						\
	}								\
	static inline long SYSC##name(__MAP(x,__SC_DECL,__VA_ARGS__))

讲解:
SYSCALL_DEFINEx		x代表有几个参数
##			代表连接符
__VA_ARGS__		表示前方 ... 的可变参数
```

## 展开*linux/net/socket.c* 文件中的宏  
```c
SYSCALL_DEFINE3(socket, int, family, int, type, int, protocol)
```

**一次展开** #define SYSCALL_DEFINE3(name, \.\.\.)  

name=socket  
\.\.\.=int, family, int, type, int, protocol
```c
SYSCALL_DEFINEx(3, _socket,  int, family, int, type, int, protocol)
```

**二次展开** #define SYSCALL_DEFINEx(x, sname, \.\.\.)  

x=3  
sname=_socket  
\.\.\.=int, family, int, type, int, protocol
```c
__SYSCALL_DEFINEx(3, _socket, int, family, int, type, int, protocol)
```

**三次展开**  #define __SYSCALL_DEFINEx(x, name, \.\.\.)

x=3  
name=_socket  
\.\.\.=int, family, int, type, int, protocol
```c
asmlinkage long sys_socket(__MAP(3,__SC_DECL,int, family, int, type, int, protocol))		\
	__attribute__((alias(__stringify(SyS_socket)));						\
static inline long SYSC_socket(__MAP(3,__SC_DECL,int, family, int, type, int, protocol));	\
asmlinkage long SyS_socket(__MAP(3,__SC_LONG,int, family, int, type, int, protocol));		\
asmlinkage long SyS_socket(__MAP(3,__SC_LONG,int, family, int, type, int, protocol))		\
{												\
	long ret = SYSC_socket(__MAP(3,__SC_CAST,int, family, int, type, int, protocol));	\
	__MAP(3,__SC_TEST,int, family, int, type, int, protocol);				\
	__PROTECT(3, ret,__MAP(x,__SC_ARGS,int, family, int, type, int, protocol));		\
	return ret;										\
}												\
static inline long SYSC_socket(__MAP(3,__SC_DECL,int, family, int, type, int, protocol))
```

**第四次展开**  #define __MAP(n,...)  

n=3  
\.\.\.在多个地方展开  
\.\.\.=__SC_DECL,int, family, int, type, int, protocol  
\.\.\.=__SC_LONG,int, family, int, type, int, protocol  
\.\.\.=__SC_CAST,int, family, int, type, int, protocol  
\.\.\.=__SC_TEST,int, family, int, type, int, protocol  
\.\.\.=__SC_ARGS,int, family, int, type, int, protocol  

以__SC_DECL为例展开,__SC_LONG,__SC_CAST,__SC_TEST,__SC_ARGS类似  
```c
#define __MAP(n,...) __MAP##n(__VA_ARGS__)展开为
__MAP3(__SC_DECL,int, family, int, type, int, protocol)

#define __MAP3(m,t,a,...) m(t,a), __MAP2(m,__VA_ARGS__)展开为
__SC_DECL(int, family), __MAP2(__SC_DECL,int, type, int, protocol)

#define __MAP2(m,t,a,...) m(t,a), __MAP1(m,__VA_ARGS__)展开为
__SC_DECL(int, type), __MAP1(__SC_DECL,int, protocol)

#define __MAP1(m,t,a) m(t,a)展开为
__SC_DECL(int, protocol)

将__MAP3,__MAP2,__MAP1组合__MAP(3,__SC_DECL,int, family, int, type, int, protocol)
__SC_DECL(int, family), __SC_DECL(int, type), __SC_DECL(int, protocol)
```

**最终展开结果** 没写完整实在不想再展开了  
```c
asmlinkage long sys_socket(int family, int type, int protocol)			\
	__attribute__((alias(__stringify(SyS_socket)));				\
static inline long SYSC_socket(int family, int type, int protocol);		\
asmlinkage long SyS_socket(__typeof(__builtin_choose_expr(__TYPE_IS_LL(int), 0LL, 0L)) family, __typeof(__builtin_choose_expr(__TYPE_IS_LL(int), 0LL, 0L)) type, __typeof(__builtin_choose_expr(__TYPE_IS_LL(int), 0LL, 0L)) protocol);\
asmlinkage long SyS_socket(__typeof(__builtin_choose_expr(__TYPE_IS_LL(int), 0LL, 0L)) family, __typeof(__builtin_choose_expr(__TYPE_IS_LL(int), 0LL, 0L)) type, __typeof(__builtin_choose_expr(__TYPE_IS_LL(int), 0LL, 0L)) protocol)\
{										\



	return ret;								\
}										\
static inline long SYSC_socket(int family, int type, int protocol)
```  
**知识点:asmlinkage 宏标志**  
```c
函数定义前加宏asmlinkage,表示这些函数通过堆栈而不是通过寄存器传递参数.

gcc编译器在汇编过程中调用c语言函数时传递参数有两种方法:
一种是通过堆栈,另一种是通过寄存器.
特别重要:缺省时采用寄存器.
假如你要在你的汇编过程中调用c语言函数,并且想通过堆栈传递参数.你定义的c函数时要在函数前加上宏asmlinkage
```

**知识点:__attribute__((alias(__stringify(SyS_socket)))**  
```
asmlinkage long sys_socket(int family, int type, int protocol) __attribute__((alias(__stringify(SyS_socket)))

1. __attribute__((alias(SyS_socket)))
含义为:给SyS_socket取个别名为sys_socket
所以相当于
oldname=SyS_socket
newname=sys_socket

2. __stringify宏

/* Indirect stringification.  Doing two levels allows the parameter to be a
 * macro itself.  For example, compile with -DFOO=bar, __stringify(FOO)
 * converts to "bar".
 */
 
#define __stringify_1(x...)	#x
#define __stringify(x...)	__stringify_1(x)

作用如下
#define AAA BBB
#define BBB CCC
#define CCC DDD

printf("stringify(AAA): %s\n", __stringify(AAA));
运行结果:可以输出套娃的最终结果
stringify(AAA): DDD


gcc编译命令
gcc test.c -o test

预处理:test.i就是预处理文件
gcc -E test.c -o test.i

生成汇编文件(使用O2优化,某些场景不要用优化 gcc -O2 -S test.c)
gcc -S test.c -o test.s
```

[gcc常用命令](https://www.cnblogs.com/ggjucheng/archive/2011/12/14/2287738.html)  
[define展开参考](https://blog.csdn.net/hxmhyp/article/details/22699669)  

**不明白的知识点**  
[BUILD_BUG_ON_ZERO](http://frankchang0125.blogspot.com/2012/10/linux-kernel-buildbugonzero.html)  
[__same_type](http://frankchang0125.blogspot.com/2012/10/linux-kernel-arraysize.html)  

--------
# 二. 添加系统调用 *未完待续*

## linux/include/uapi/asm-generic/unistd.h
```c
#define __NR_syscalls 291  最大系统调用数,当系统添加调用后,这个数也要随之增大

函数声明也会写在这里
```

