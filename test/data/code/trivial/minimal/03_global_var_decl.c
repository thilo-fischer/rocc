/*
 * Same as 01_comments.c, but with some declarations for global
 * variables added.
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

// invalid variable declarations that should give an error (or warning?), but don't yet get detected by rocc as invalid declarations
bool b_var; // FIXME requires #include <stdbool.h>
void v_var; // FIXME? should void variable give warning or error?
void *pv_var;

// main function of the program
int main(int argc, char **argv)
{
  /* return success */
  return 0;
}
