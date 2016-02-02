/*
 * Same as 09_include.c, but with some preprocessor conditionals.
 */

#include "10_include.h"

// various definitions and references of global variables
int i_var = FORTYTWO;
const unsigned short int cusi_var = i_var;
static long long sll_var = 0x1122334455667788ll;
char c_var_a = 'a', c_var_b = c_var_a;
char *pc_var_a = "pc_var_a";
char c_var_c = 99, *pc_var_b = "pc_var_b";
char *pc_var_c = POINTER_TO(c_var_c), c_var_d = *pc_var_b;

// some function definitions
void v_func() {};
int i_func_v(void)
{
  return 0;
}

// main function of the program
int main(int argc, char **argv)
{
  // some declarations and definitions of function local variables
  const char lcc_var = "lcc_var";
  const unsigned char lcuc_var = '\0';
  
  /* return success */
  return lcuc_var; // reference to local variable
}

// some more function definitions
int i_func_i(int i_param) {
  return i_param;
}

#ifdef NO_SUCH_MACRO
// FIXME #error errornous preprocessor-conditional branch
#elif defined(FORTYTWO) && FORTYTWO == 42
char *pc_func_(unsigned int i_param, char c_param, char *pc_param)
{
  return pc_param;
}
#else
char *foobar = "foobar";
char *pc_func_ui_c_pc(unsigned int i_param, char c_param, char *pc_param)
{
  return foobar;
}
#endif
