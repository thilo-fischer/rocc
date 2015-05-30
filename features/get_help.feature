Feature: Get help

  As an user
  I want to have reference documentation available form the program itself
  So I don't have to remember all details of the invocation syntax and the available command line arguments but can look these things up easily when working with rocc.

  Scenario: Get help on program invekation
    When I run `rocc --help`
    Then the output should match /^Usage:\s+rocc\s/

  Scenario: Get help on available commands
    When I run `rocc -e help`
    Then the output should match /ls\s+.*[Ll]ist/
    And  the output should match /help\s+.*[Hh]elp/

  Scenario: Get help on a specific command
    When I run `rocc -e 'help help'`
    Then the output should match /^Usage:\s+help/
