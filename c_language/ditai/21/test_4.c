// #include <stdio.h>
// #include <malloc.h>

#define MALLOC(type, x) (type*)malloc(sizeof(type)*x)    //向堆空间申请 x个type 空间

#define FREE(p) (free(p), p=NULL)    //使用逗号表达式,释放p指向的堆空间,并将指针p置空

#define LOG(s) printf("[%s] {%s:%d} %s \n", __DATE__, __FILE__, __LINE__, s)    //打印编译相关信息

#define FOREACH(i, m) for(i=0; i<m; i++)    //实现for循环
#define BEGIN {
#define END   }

int main()
{
    int x = 0;
    int* p = MALLOC(int, 5);    //指针p指向 在堆空间申请5个int空间.  C语言无法将类似int这种类型作为参数进行传递

    LOG("Begin to run main code...");

    FOREACH(x, 5)
    BEGIN
        p[x] = x;
    END

    FOREACH(x, 5)
    BEGIN
        printf("%d\n", p[x]);
    END

    FREE(p);

    LOG("End");

    return 0;
}