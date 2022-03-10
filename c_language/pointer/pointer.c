#include <stdio.h>
int Max(int a, int b)
{
	return a > b ? a : b;
}
int Max2(int a, char b)
{
	return a > b ? a : b;
}
int Sum(int a, int b)
{
	return a + b;
}

//※※※函数指针无法作为函数返回值
int(*)(int, int) returnFunction(int(*pMax)(int, int))
{
	return pMax;
}

//函数指针充当函数参数
void print(int(*pMax)(int, int), int a, int b)
{
	printf("%d\n", pMax(a,b));
}

int main()
{
	int* p = NULL;
	int (*pMax)(int a, int b) = NULL;
	//上面一句话等价于下面两句话
	int (*ppMax)(int, int);	//一般形参会被忽略
	//以上是定义函数指针

	ppMax = NULL;

	//ppMax = Max2; 错误:由于Max2的形参不是(int,int)所以会警告

	//赋值方式两种等价
	ppMax = Max;
	ppMax = &Max;

	//使用方式:1.直接用函数指针替换函数名调用即可
	//Max(1,2);
	printf("%d\n", ppMax(1,2));
	printf("%d\n", (*ppMax)(1,2));//*ppMax是指针的解引用

	//函数指针充当函数参数
	//回调函数:统一接口,不同实现
	print(Max, 1, 2);	//最大值
	print(Sum, 1, 2);	//求和

	return 0;
 }
