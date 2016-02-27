Feature: Code Analysis

  As an user
  I want rocc to analyse my codebase and get some sort of "understanding" of the code
  So it will be able to do fancy operations on the codebase

@announce-cmd
@announce-stdout
@announce-stderr

  Scenario Outline: Understand symbol definitions and declarations
    When I invoke "ls" on "<code>"
    Then the output should look as specified by "<expect>"

  Examples:
    | code                                  | expect                                           |
    | trivial/minimal/00_main.c             | trivial/minimal/00_main_ls                       |
    | trivial/minimal/01_comment.c          | trivial/minimal/01_comment_ls                    |
    | trivial/minimal/02_argc_argv.c        | trivial/minimal/02_argc_argv_ls                  |
    | trivial/minimal/03_global_var_decl.c  | trivial/minimal/03_global_var_decl_ls            |
    | trivial/minimal/05_var_def.c          | trivial/minimal/05_var_def_ls                    |
    | trivial/minimal/06_var_ref.c          | trivial/minimal/06_var_ref_ls                    |
    | trivial/minimal/07_func_decl.c        | trivial/minimal/07_func_decl_ls                  |
    | trivial/minimal/08_func_def.c         | trivial/minimal/08_func_def_ls                   |
    | trivial/minimal/09_macro.c            | trivial/minimal/09_macro_ls                      |
    | trivial/minimal/10_include.c          | trivial/minimal/10_include_ls                    |

  Scenario Outline: Understand preprocessor conditional directives and list probability estimations of specifications
    When I invoke "ls --spec" on "<code>"
    Then the output should look as specified by "<expect>"

    # TODO_W should notice expression 1 is always true (=> planned feature) and thus should contain `v i_var_1' instead of `v i_var_1///\s*///[0.5]'. 
    # c01_if_else_endif.c output should contain `v i_var_1' instead of `v i_var_1///\s*///[0.5]' and no `i_var_no_1'
  Examples:
    | code                                       | expect                                                |
    | trivial/minimal/11_ppcond.c                | trivial/minimal/11_ppcond_ls_--spec                   |
    | specific/preprocessor/c00_if_endif.c       | specific/preprocessor/c00_if_endif_ls_--spec          |
    | specific/preprocessor/c01_if_else_endif.c  | specific/preprocessor/c01_if_else_endif_ls_--spec     |
    | specific/preprocessor/c02_elif.c           | specific/preprocessor/c02_elif_ls_--spec              |

  Scenario Outline: Understand preprocessor conditional directives and list conditions of specifications
    # FIXME format string
    When I invoke "ls --spec --format +%i@%_c" on "<code>"
    Then the output should look as specified by "<expect>"

  Examples:
    | code                                       | expect                                                            |
    | specific/preprocessor/c00_if_endif.c       | specific/preprocessor/c00_if_endif_ls_--spec_--format_i_C         |
    | specific/preprocessor/c01_if_else_endif.c  | specific/preprocessor/c01_if_else_endif_ls_--spec_--format_i_C    |
    | specific/preprocessor/c02_elif.c           | specific/preprocessor/c02_elif_ls_--spec_--format_i_C             |

  @wip
  Examples:
    | code                                       | expect                                                            |
    | specific/preprocessor/c03_nested.c         | specific/preprocessor/c03_nested_ls_--spec_--format_i_C           |

  @planned
  Scenario: List function local variables
    When I invoke "cd main; ls" on "trivial/minimal/04_local_var_decl.c"
    Then the output should contain exactly:
"""
v lcc_var
v lcuc_var
"""

