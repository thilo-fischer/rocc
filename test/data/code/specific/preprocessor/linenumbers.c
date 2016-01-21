#include <stdio.h>

#define MACRO \
    printf("%d\n", __LINE__); \
    printf("%d\n", __LINE__);

int main(void)
{
    printf("%d\n", __LINE__);

#line 42
    printf("%d\n", __LINE__);

    printf("%d\n", __LINE__); \
    printf("%d\n", __LINE__);

    MACRO;

    MACRO; \
    MACRO;

    MACRO; MACRO;

    return 0;
}
