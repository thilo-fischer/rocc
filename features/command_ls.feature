Feature: Command `ls'

  As an user exploring C source files
  I want a list of the symbols declared or defined in the code under investigation
  So it will help me to analyse and further process that code

@announce-cmd
@announce-stdout
@announce-stderr

  Scenario Outline: List all externally declared symbols in short form
    When I invoke as "ls" on "<input>"
    Then the output should look as specified in the according file

  Scenarios: minimal
    | input                                                                          |
    | minimal/main.c                                                                 |
#   | simple_01/main_00.c                                                            |
#   | simple_01/main_01.c                                                            |
#   | simple_01/main_02.c                                                            |
#   | simple_01/main_03.c                                                            |
#   | simple_01/main_04.c                                                            |
#   | simple_01/main_05.c                                                            |
#   | hello_world/hello_world.c                                                      |
#   | indented_hello_world/indented_hello_world_00.c                                 |
#   | indented_hello_world/indented_hello_world_01.c                                 |
