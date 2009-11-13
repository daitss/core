Feature: Boss stash
  In order take a package out of the processing context
  As an operator
  I want to start stash the package

  Scenario: stash a single package
    Given I submit a package
    When I type "boss stash aip-0 /tmp"
    Then the package should be in /tmp
    And it should not be in the workspace

  Scenario: stash a processing package
    Given I submit a package 
    When I type "boss start aip-0" 
    And I type "boss stash aip-0 /tmp"
    Then it should return status 2
    And the package should not be in /tmp
    And it should be in the workspace
