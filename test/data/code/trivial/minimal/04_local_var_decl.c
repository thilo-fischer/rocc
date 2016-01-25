/*
 * Same as 02_global_var_decl.c, but with some declarations for
 * function local variables added.
 */

// various declarations of global variables
int i_var;
const unsigned short int cusi_var;
extern signed es_var;
static long long sll_var;
char c_var_a, c_var_b;
char *pc_var_a;
char c_var_c, *pc_var_b;
char *pc_var_c, c_var_d;

// main function of the program
int main(int argc, char **argv)
{
  // some declarations of function local variables
  const char lcc_var;
  const unsigned char lcuc_var;
  
  /* return success */
  return 0;
}
