Feature: Command `ls'

  As an user exploring C source files
  I want a list of the symbols declared or defined in the code under investigation
  So it will help me to analyse and further process that code

@announce-cmd
@announce-stdout
@announce-stderr


  Scenario Outline: List all externally declared symbols in default format
    When I invoke "ls" on "<code>"
    Then the output should look as specified by "<expect>"

  Examples:
    | code                                  | expect                                           |
    | trivial/minimal/00_main.c             | trivial/minimal/00_main_ls                       |
    | trivial/minimal/01_comment.c          | trivial/minimal/01_comment_ls                    |
    | trivial/minimal/02_argc_argv.c        | trivial/minimal/02_argc_argv_ls                  |
    | trivial/minimal/03_global_var_decl.c  | trivial/minimal/03_global_var_decl_ls            |
    | trivial/minimal/04_local_var_decl.c   | trivial/minimal/04_local_var_decl_ls             |
    | trivial/minimal/05_var_def.c          | trivial/minimal/05_var_def_ls                    |
    | trivial/minimal/06_var_ref.c          | trivial/minimal/06_var_ref_ls                    |
    | trivial/minimal/07_func_decl.c        | trivial/minimal/07_func_decl_ls                  |
    | trivial/minimal/08_func_def.c         | trivial/minimal/08_func_def_ls                   |
    | trivial/minimal/09_macro.c            | trivial/minimal/09_macro_ls                      |
    | trivial/minimal/10_include.c          | trivial/minimal/10_include_ls                    |

  Scenario:
    When I invoke "ls --short" on "trivial/minimal/10_include.c"
    Then the output should look as specified by "trivial/minimal/10_include_ls_--short"

  #Scenario:
  #  When I invoke "ls --long" on "trivial/minimal/10_include.c"
  #  Then the output should look as specified by "trivial/minimal/10_include_ls_--long"

  Scenario Outline: List specifications of all externally declared symbols in default format
    When I invoke "ls --spec" on "<code>"
    Then the output should look as specified by "<expect>"

  Examples:
    | code                                  | expect                                           |
    | trivial/minimal/05_var_def.c          | trivial/minimal/05_var_def_ls_--spec             |
    | trivial/minimal/08_func_def.c         | trivial/minimal/08_func_def_ls_--spec            |
    | trivial/minimal/09_macro.c            | trivial/minimal/09_macro_ls_--spec               |
    | trivial/minimal/10_include.c          | trivial/minimal/10_include_ls_--spec             |
    | trivial/minimal/11_ppcond.c           | trivial/minimal/11_ppcond_ls_--spec              |



  Scenario Outline: List the most siginficant specification of each externally declared symbol in default format
    When I invoke "ls --spec --unique" on "<code>"
    Then the output should look as specified by "<expect>"

  Examples:
    | code                                  | expect                                           |
    | trivial/minimal/08_func_def.c         | trivial/minimal/08_func_def_ls_--spec_--unique   |
    | trivial/minimal/10_include.c          | trivial/minimal/10_include_ls_--spec_--unique    |
    # FIXME_W should contain `f pc_func_ui_c_pc(3)' (and possibly `F pc_func_ui_c_pc(3)   [...]') instead of `F pc_func_ui_c_pc(3)'
    | trivial/minimal/11_ppcond.c           | trivial/minimal/11_ppcond_ls_--spec_--unique     |


  @broken
  Scenario Outline: List all externally declared symbols in default format
    When I invoke "ls -R" on "<code>"
    Then the output should look as specified by "<expect>"

  Examples:
    | code                                  | expect                                           |
    | trivial/minimal/04_local_var_decl.c   | trivial/minimal/04_local_var_decl_ls_--recursive |
    #| trivial/minimal/05_var_def.c          | trivial/minimal/05_var_def_ls_--recursive        |


  @planned
  Scenario: Get help on format used by ls
    When I run `rocc -e 'ls --legend'`
    Then the output should look as specified by "general/ls_--legend"
  
  @planned
  Scenario: Get help on format used by ls -l
    When I run `rocc -e 'ls -l --legend'`
    Then the output should look as specified by "general/ls_-l_--legend"


