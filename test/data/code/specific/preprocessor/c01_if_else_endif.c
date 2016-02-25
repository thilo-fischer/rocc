/*
 * Like c00_if_endif.c, but with else clauses.
 */

#if 1
int i_var_1;
#else
int i_var_no_1;
#endif

#if defined(FOO)
int i_var_foo;
#else
int i_var_no_foo;
#endif

#ifdef BAR
int i_var_bar;
#else
int i_var_no_bar;
#endif
