/*
 * Like c00_if_endif.c, but with else and elif clauses.
 */

#if 1
int i_var_1;
#elif 42
int i_var_no_1_but_42;
#endif

#if defined(FOO)
int i_var_foo;
#elif defined(BAR)
int i_var_no_foo_but_bar;
#else
int i_var_neither_foo_nor_bar;
#endif
