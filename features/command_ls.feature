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
    | trivial/minimal/main.c                | trivial/minimal/ls                    |
#    | trivial/hello-world/hello-world.c     | trivial/hello-world/ls                |
#    | simple_01/main_00.c                                                            |
#    | simple_01/main_01.c                                                            |
#    | simple_01/main_02.c                                                            |
#    | simple_01/main_03.c                                                            |
#    | simple_01/main_04.c                                                            |
#    | simple_01/main_05.c                                                            |
#    | hello_world/hello_world.c                                                      |
#    | indented_hello_world/indented_hello_world_00.c                                 |
#    | indented_hello_world/indented_hello_world_01.c                                 |


#  Scenario: Get help on format used by ls
#    When I run `rocc -e 'ls --legend'`
#    Then the output should look as specified by "general/ls_--legend"
#
#  Scenario: Get help on format used by ls -l
#    When I run `rocc -e 'ls -l --legend'`
#    Then the output should look as specified by "general/ls_-l_--legend"

