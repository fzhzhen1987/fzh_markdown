#define ERROR -1
#define PATH1 "D:\test\test.c"
#define PATH2 D:\test\test.c
#define PATH3 D:\test\
test.c

int main()
{
    int err = ERROR;
    char* p1 = PATH1;
    char* p2 = PATH2;
    char* p3 = PATH3;
}