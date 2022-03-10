#include <stdio.h>

#define _SUM_(a, b) (a) + (b)
#define _MIN_(a, b) ((a) < (b) ? (a) : (b))
#define _DIM_(a) sizeof(a)/sizeof(*a)    //求数组中有几个元素

int main()
{
    int a = 1;
    int b = 2;
    int c[4] = {0};

    int s1 = _SUM_(a, b);
    int s2 = _SUM_(a, b) * _SUM_(a, b);
    int m = _MIN_(a++, b);
    int d = _DIM_(c);

    printf("s1 = %d\n", s1);
    printf("s2 = %d\n", s2);
    printf("m = %d\n", m);
    printf("d = %d\n", d);

    return 0;
}
