// #include <stdio.h>

void def()
{
    #define PI 3.1415926
    #define AREA(r) r * r * PI
}

double area(double r)
{
    return AREA(r);
}

int main()
{
    double r = area(5);

    // printf("PI = %f\n", PI);
    // printf("d = 5; a = %f\n", r);
    
    return 0;
}