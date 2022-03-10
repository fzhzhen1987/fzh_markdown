#include <stdio.h>
//1.给简单的数据类型起别名
typedef int 整数;
//2.给数组起别名
typedef int ARRAY[3];
//万能看typedef的方法
//1.直接用别名定义的名字替换别名
//typedef int arr[3];
//2.去掉typedef,剩下的就是你定义的东西
typedef int ARRAY2D[2][2];

int Max(int a, int b)
{
	return a > b ? a : b;
}
//3.函数指针起别名
typedef int(*pMax)(int, int);
//函数指针作为函数参数
pMax returnFunction(pMax p, int a, int b)
{
	printf("%d\n", p(a, b));
	return p;
}

int main()
{
	整数 a = 10;

	ARRAY arr;

	for (int i = 0; i < 3; i++)
	{
		arr[i] = i;
		printf("%d\n", arr[i]);
	}

	ARRAY num[2];	//int num[2][3];

	ARRAY2D num2d;	//int num2d[2][2];

	pMax p = NULL;
	//int (*p)(int, int) = NULL;
	//很少见,基本不这样用,函数指针更多的使用方法是:调用函数,充当函数参数
	p = returnFunction(Max, 1, 2);
	printf("%d\n", p(1, 2));
	//上面两句话等价于下面一句话
	int result = returnFunction(Max, 1, 2)(10, 11);
	printf("%d\n", result);
	//先把Max函数指针返回给p,再用p调用函数再打印(10,11)

	return 0;
}
