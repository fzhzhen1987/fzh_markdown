# 位操作:Align(向上和向下取整

- [1. Align向下对齐 ALIGN](#1)  
- [2. Align向上对齐 ALIGNUP](#2)  

<h4 id="1">[1. Align向下对齐 ALIGN]</h>  

```c
#define ALIGN(value, align)	((value) & ~((align) - 1))
```

- 举例计算: ALIGN(13,4)  
	1. (align - 1) =3, 二进制为 0000 0011  
	1. (align - 1)取反, 二进制为 1111 1100  
	1. value(13) 与 ~(align - 1) 按位与操作为12  
		```text
		    0000 1101
		&   1111 1100
		-------------
		    0000 1100
		```

<h4 id="2">[2. Align向上对齐 ALIGNUP]</h>  

```c
#define ALIGNUP(value, align)	ALIGN((value) + ((align) - 1), align)
```

- 举例计算: ALIGNUP(13,4)  
	1. (value) + ((align) - 1) = 13 + 4 - 1 = 16  
	1. 所以ALIGN(16,4)  
	1. (4 - 1)取反的二进制为 1111 1100  
	1. 取反的结果与16与操作 结果为16  
		```text
		    0001 0000
		&   1111 1100
		-------------
		    0001 0000
		```

