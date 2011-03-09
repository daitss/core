Feature: interactive submission

  Background:
    Given I am logged in as an affiliate of "ACT"
    And account "ACT" has a project "PRJ"

  Scenario: package that should not give a successful response
    Given I go to the packages page
    When I attach the sip "scrambled" to "sip"
    And I press "Submit"
    Then I should see "error extracting"

  Scenario Outline: packages that should reject or submit
    Given I go to the packages page
    When I attach the sip "<package>" to "sip"
    And I press "Submit"
    Then I should see "<action>" within ".notice"
    And I should see "<note>"
    Examples:
      | package            | action | note                       |
      | haskell-nums-pdf   | submit |                            |
      | undescribed        | submit | undescribed file: file.txt |
      | missing-descriptor | reject | missing descriptor         |
      | bad-account        | reject | has wrong account          |
      | bad-project        | reject | has wrong project          |

  Scenario: submission notes
    Given I go to the packages page
    When I attach the sip "haskell-nums-pdf" to "sip"
    And I fill in "note" with "a note"
    And I press "Submit"
    Then I should see "a note"

  Scenario: ignore note if not filled in
    Given I go to the packages page
    When I attach the sip "haskell-nums-pdf" to "sip"
    And I press "Submit"
    Then I should not see "a note"

  Scenario: submission to list
    Given I go to the packages page
    When I attach the sip "haskell-nums-pdf" to "sip"
    And I fill in "list" with "mylist"
    When I press "Submit"
    Then I should see "mylist"

  Scenario: ignore batch if not filled in
    Given I go to the packages page
    When I attach the sip "haskell-nums-pdf" to "sip"
    When I press "Submit"
    Then I should not see "mylist"
