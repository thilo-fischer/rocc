/*
 * Same as 03_local_var_decl.c, but with some variable definitions.
 */

// various declarations of global variables
int i_var = 42;
const unsigned short int cusi_var = 4711us;
extern signed es_var;
static long long sll_var = 0x1122334455667788ll;
char c_var_a, c_var_b = 'b';
char *pc_var_a = "pc_var_a";
char c_var_c = 99, *pc_var_b = "pc_var_b";
char *pc_var_c, c_var_d;

// main function of the program
int main(int argc, char **argv)
{
  // some declarations of function local variables
  const char lcc_var = "lcc_var";
  const unsigned char lcuc_var = '\0';
  
  /* return success */
  return 0;
}
