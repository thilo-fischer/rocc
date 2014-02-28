#include <stdio.h>

#include "test01.h"

#define PLUS +

int main(void)
{
    int a, b, c;
    a=b+c-20*2;

    int i;
    int j;

    i = 3;
    j = 3;
    printf("(i PLUS++ j) == %d | i == %d | j == %d\n", i PLUS++ j, i, j);

    i = 3;
    j = 3;
    printf("(i +PLUS+ j) == %d | i == %d | j == %d\n", i +PLUS+ j, i, j);

    i = 3;
    j = 3;
    printf("(i ++PLUS j) == %d | i == %d | j == %d\n", i ++PLUS j, i, j);

    i = 3;
    j = 3;
    printf("(i    +++ j) == %d | i == %d | j == %d\n", i    +++ j, i, j);

    i = 3;
    j = 3;
    printf("((i++)  + j) == %d | i == %d | j == %d\n", (i++)  + j, i, j);

    printf("5 == %d | +5 == %d | + 5 == %d | + + 5 == %d | + + +5 == %d \n",
           5, +5, + 5, + + 5, + + +5);

    printf("5 == %d | +5 == %d | - 5 == %d | - + 5 == %d | - + -5 == %d \n",
           5, +5, - 5, - + 5, - + -5);

    printf("Hello, World\n");
    
    return 0;
}
