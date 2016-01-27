Feature: Command `ls'

  As an user exploring C source files
  I want a list of the symbols declared or defined in the code under investigation
  So it will help me to analyse and further process that code

@announce-cmd
@announce-stdout
@announce-stderr

  Scenario Outline: List all externally declared symbols in short form
    When I invoke "ls" on "<code>"
    Then the output should look as specified by "<expect>"

  Scenarios: minimal
    | code                                  | expect                                |
    | trivial/minimal/00_main.c             | trivial/minimal/00_main_ls            |
    | trivial/minimal/01_comment.c          | trivial/minimal/01_comment_ls         |
#    | trivial/minimal/02_argc_argv.c        | trivial/minimal/02_argc_argv_ls       |
#    | trivial/minimal/03_global_var_decl.c  | trivial/minimal/03_global_var_decl_ls |
#    | trivial/minimal/04_local_var_decl.c   | trivial/minimal/04_local_var_decl_ls  |
#    | trivial/minimal/05_var_def.c          | trivial/minimal/05_var_def_ls         |
#    | trivial/minimal/06_var_ref.c          | trivial/minimal/06_var_ref_ls         |
#    | trivial/minimal/07_func_decl.c        | trivial/minimal/07_func_decl_ls       |
#    | trivial/minimal/08_func_def.c         | trivial/minimal/08_func_def_ls        |
#    | trivial/minimal/09_macro.c            | trivial/minimal/09_macro_ls           |
#    | trivial/minimal/10_include.c          | trivial/minimal/10_include_ls         |
#    | trivial/minimal/11_ppcond.c           | trivial/minimal/11_ppcond_ls          |
#    | trivial/hello-world/hello-world.c    | trivial/hello-world/ls                |
#    | indented_hello_world/indented_hello_world_00.c                                 |
#    | indented_hello_world/indented_hello_world_01.c                                 |


#  Scenario: Get help on format used by ls
#    When I run `rocc -e 'ls --legend'`
#    Then the output should look as specified by "general/ls_--legend"
#
#  Scenario: Get help on format used by ls -l
#    When I run `rocc -e 'ls -l --legend'`
#    Then the output should look as specified by "general/ls_-l_--legend"

