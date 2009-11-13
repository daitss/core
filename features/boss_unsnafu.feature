Feature: Boss unsnafu
  In order reset the state of snafu'ed package
  As an operator
  I want to start unsnafu them

  Scenario: unsnafu all packages
    Given I submit a package
    And it is tagged SNAFU
    When I type "boss unsnafu aip-0" 
    And I type "boss list snafu"
    Then they should not be in the list

  Scenario: unsnafu a single package
  Scenario: unsnafu a non-snafu package
