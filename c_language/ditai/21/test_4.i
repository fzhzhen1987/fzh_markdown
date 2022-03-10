# 0 "test_4.c"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 0 "<command-line>" 2
# 1 "test_4.c"
# 14 "test_4.c"
int main()
{
    int x = 0;
    int* p = (int*)malloc(sizeof(int)*5);

    printf("[%s] {%s:%d} %s \n", "Jul 24 2022", "test_4.c", 19, "Begin to run main code...");

    for(x=0; x<5; x++)
    {
        p[x] = x;
    }

    for(x=0; x<5; x++)
    {
        printf("%d\n", p[x]);
    }

    (free(p), p=NULL);

    printf("[%s] {%s:%d} %s \n", "Jul 24 2022", "test_4.c", 33, "End");

    return 0;
}
