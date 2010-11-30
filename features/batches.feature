Feature: CRUD for batches

  Scenario: convert a whitespace delimited list of IEIDs to a batch
    Given the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I goto "/batches"
    And I fill in "name" with "foo"
    And I fill in "packages" with: 
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    When I press "Submit"
    Then I should be redirected
    And I click on "foo"
    And I should have a batch containing
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|

  Scenario: add to an existing batch
    Given batch "foo" with the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I goto "/batches"
    And I click on "foo"
    And I fill in "packages" with:
      |E00000000_000001|
      |E00000000_000003|
      |E00000000_000004|
    When I press "Submit"
    Then I should be redirected
    And I should have a batch containing:
      |E00000000_000001|
      |E00000000_000003|
      |E00000000_000004|

  Scenario: delete a batch
    Given batch "foo" with the following packages:
      |E00000000_000001|
      |E00000000_000002|
      |E00000000_000003|
    And I goto "/batches"
    And I click on "foo"
    And I click on "delete batch"
    Then I should be redirected
    And I should not have batch "foo"





