/**
 * @file
 * @brief Simple C code containing several different <em>"CodeObjects"</em> rocc shall handle.
 */

#include <stdio.h>
#include <stdlib.h>

#include "indented_hello_world.h"

#define INDENT_META_FORMAT ("%% %ds%%s\n")
#define MAX_INDENT_FORMAT ("% " ARG_TO_STR(MAX_INDENTATION) "s%s\n")

// fixme: there must be some way to do this more elegant ...
static inline void print_indented(short int depth, const char *string)
{
    char format[] = MAX_INDENT_FORMAT;
    sprintf(format, INDENT_META_FORMAT, depth);
    printf(format, "", string);
}

int main(int argc, char **argv)
{
    unsigned int i;
    for (i = 0; i < MAX_INDENTATION; ++i)
        {
            print_indented(i, "Hello world!");
        }
    return EXIT_SUCCESS;
}
