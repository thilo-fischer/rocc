/**
 * @file
 * @brief Simple C code containing several different <em>"CodeObjects"</em> ooccor shall handle.
 */

#include <stdio.h>

#include <simple-but-comprehensive.h>

#define INDENT_META_FORMAT ("%% %ds%%s\n")
#define MAX_INDENT_FORMAT ("% " #MAX_INDENTATION "s%s\n")

// fixme: there must be some way to do this more elegant ...
static inline void print_indented(short int depth, char *string)
{
    char format[] = MAX_INDENT_FORMAT;
    snprintf(format, INDENT_META_FORMAT, depth);
    printf(format, string);
}

int main(void)
{
    unsigned int i;
    for (i = 0; i < MAX_INDENTATION; ++i)
        {
            print_indented(i, "Hello world!");
        }
    return EXIT_SUCCESS;
}
