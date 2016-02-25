/*
 * Basic test for preprocessor conditionals
 */

#if 1
int i_var_1;
#endif

#if defined(FOO)
int i_var_foo;
#endif

#ifdef BAR
int i_var_bar;
#endif
