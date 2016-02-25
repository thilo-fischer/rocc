/*
 * Like c02_elif.c, but with nested preprocessor conditionals.
 */

#if 1
  int i_var_1;
  #ifdef FOO
    int i_var_1_and_foo;
  #else
    int i_var_1_and_no_foo;
  #endif
#else
  int i_var_no_1;
# if defined(FOO)
    int i_var_no_1_and_foo;
#   if defined(BAR)
      int i_var_no_1_and_foo_and_bar;
#   else
      int i_var_no_1_and_foo_no_bar;
#   endif
# elif defined(BAR)
    int i_var_no_1_no_foo_but_bar;
# else
    int i_var_neither_1_nor_foo_nor_bar;
# endif
#endif
