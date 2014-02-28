// see if it works ... this program should behave diffrently bedending on whether preprocessing and compilation is done in common (`gcc __FILE__') or separately (`gcc -E __FILE__ > foo.i && gcc foo.i').

#include <stdio.h>

#define PLUS +
#define DQ "

void foo(int x, ...) {
}

int main(void)
{
    // foo(42, DQ , DQ); //"foo(" DG

    printf("`%s' + `%s'\n", DQ, ", ", DQ, "FOO");
    
    return 0;
}
