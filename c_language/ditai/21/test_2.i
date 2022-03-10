# 0 "test_2.c"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 0 "<command-line>" 2
# 1 "test_2.c"






int main()
{
    int a = 1;
    int b = 2;
    int c[4] = {0};

    int s1 = (a) + (b);
    int s2 = (a) + (b) * (a) + (b);
    int m = ((a++) < (b) ? (a++) : (b));    //a++ 执行了2次
    int d = sizeof(c)/sizeof(*c);






    return 0;
}
