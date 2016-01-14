#include <stdio.h>
 
int main(void)
{
    printf("%d\n", (sizeof  (int *)) + 2) ;
    printf("%d\n",  sizeof ((int *)  + 2));
    printf("%d\n",  sizeof  (int *)  + 2) ;
    return 0;
}
