/*
 * Same as 08_macro.c, but split into source and header file.
 */

#define NOTHING
#define FORTYTWO 42
#define POINTER_TO(VAR) (&VAR)

// various declarations of global variables
int i_var;
const unsigned short int cusi_var;
extern signed es_var;
static long long sll_var;
char c_var_a, c_var_b;
char *pc_var_a;
char c_var_c, *pc_var_b;
char *pc_var_c, c_var_d;

// some function declarations
void v_func();
int i_func_v(void);
int i_func_i(int i_param);
char *pc_func_ui_c_pc(unsigned int i_param, char c_param, char *pc_param);
