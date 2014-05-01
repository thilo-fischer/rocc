Feature: Command `ls'

  As an user exploring C source files
  I want a list of the symbols declared or defined in the code under investigation
  So it will help me to analyse and further process that code

  Scenario Outline: List all externally declared symbols in short form
    When I invoke as "ls" on "<input>"
    Then the output should look as specified in the according file

  Scenarios: minimal
    | input               |
    | minimal/main.c      |
    | simple_01/main_00.c |

#  Scenario: List all externally declared symbols in short form 2
#    When I run `ooccor -e 'ls' '../../test/00_ordirary/indented_hello_world_00.c'`
#    Then the output should contain exactly:
#"""
#MAX_INDENTATION#
#ARG_TO_STR()#
#INDENT_META_FORMAT#
#MAX_INDENT_FORMAT#
#print_indented()
#main()
#"""
