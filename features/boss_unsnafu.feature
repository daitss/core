Feature: Boss unsnafu
  In order reset the state of snafu'ed package
  As an operator
  I want to start unsnafu them

  Scenario: unsnafu all packages
    Given I submit 2 packages
    And they are tagged SNAFU
    And I submit another package
    When I type "boss unsnafu all" 
    And I type "boss list snafu"
    Then they should not be in the list
    And the list should have 0 aips

  Scenario: unsnafu a single package
    Given I submit a package
    And it is tagged SNAFU
    When I type "boss unsnafu aip-0" 
    And I type "boss list snafu"
    Then it should not be in the list

  Scenario: unsnafu a non-snafu package
    Given I submit a package
    When I type "boss unsnafu aip-0" 
    Then it should return status 2
