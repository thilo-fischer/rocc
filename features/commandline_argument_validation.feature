Feature: Command line argument validation

  As an user
  I want the program to check the command line arguments given to it at invocation and provide helpfull error messages or warnings in case of invalid, inconsistent or unknown command line arguments
  So I will get help invoking the program in the correct manner

  Scenario: Select an invalid compiler
    When I run `ooccor --compiler foobar`
    Then the exit status should not be 0
    And  the output should contain "invalid"
    And  the output should contain "compiler"
    And  the output should contain "foobar"

  Scenario: Unsupported compiler command line arguments
    When I run `ooccor --compiler gcc -j -k -q -z`
    Then the output should contain "unsupported compiler argument"

