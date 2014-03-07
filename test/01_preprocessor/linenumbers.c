#include <stdio.h>

#define MACRO \
    printf("%d", __LINE__); \
    printf("%d", __LINE__);

int main(void)
{
    printf("%d", __LINE__);
#line 42
    printf("%d", __LINE__);

    printf("%d", __LINE__); \
    printf("%d", __LINE__);

    MACRO;

    MACRO; \
    MACRO;

    MACRO; MACRO;

    return 0;
}
