#include <stdio.h>
//void(*p)();是void print()的函数指针.	去掉变量名剩下就是指针: void(*)()


void print()
{
	printf("空类型的指针充当函数指针\n");
}

int Max(int a, int b)
{
	return a > b ? a : b;
}
int Sum(int a, int b)
{
	return a + b;
}

void printDate(int(*pMax)(int, int), int a, int b)
{
	...
}
//以一个函数指针为参数的函数指针为参数的函数
//void printDate(int(*pMax)(int, int), int a, int b) 的函数指针类型为
//void(*p)(int(*pMax)(int, int), int a, int b) ←(*+指针名)替换printDate函数名
//void(*p)(int(*)(int, int), int, int)
void userPrint(void(*p)(int(*)(int, int),int,int), int(*pMax)(int, int), int a, int b)
{
	p(pMax, a, b);
}


int main()
{
	//1.万能指针充当函数指针
	void* pVoid = NULL;
	//使用前必须做类型转换
	pVoid = print;	//print的类型: void(*)();

	//万能空指针调用函数指针时,使用前必须做类型转换
	((void(*)())pVoid)();	//调用函数指针前,必须做类型转换: (void(*)())

	(*(void(*)())pVoid)();	//调用函数指针前,必须做类型转换: (void(*)())	//解引用情况下,空指针调用函数指针

	//2.以一个函数指针为参数的函数指针为参数的函数
	
	//3.定义函数指针数组:多个函数指针的集合
	int (*pMax)(int, int) = NULL;
	int (*pArray[2])(int, int);	//[2]要先和pArray结合才能成为数组
	
	typedef int(*pXX)(int, int);	//定义函数指针类型的别名
	pXX x[2];	//使用别名定义函数指针数组

	x[0] = Max;
	x[1] = Sum;

	//int *array[2]; 是一个指针数组
	pArray[0] = Max;
	pArray[1] = Sum;
	for (int i = 0; i < 2; i++) {
		printf("%d\n", pArray[i](10, 20));
	}

	return 0;
}
