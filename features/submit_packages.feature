Feature: interactive submission

  Background:
    Given I am logged in as an affiliate of "ACT"
    And account "ACT" has a project "PRJ"

  Scenario Outline: packages that should reject or submit
    Given I go to the packages page
    When I attach the sip "<package>" to "sip"
    And I press "Submit"
    Then I should see "<action>" within ".notice"
    And I should see "<note>"
    Examples:
      | package                           | action | note                                                     |
      | haskell-nums-pdf                  | submit |                                                          |
      | mixed-case-checksums              | submit |                                                          |
      | virus                             | submit |                                                          |
      | undescribed                       | submit | undescribed file: file.txt                               |
      | checksum-mismatch                 | reject | wrong md5: ateam.tiff                                    |
      | missing-descriptor                | reject | missing descriptor                                       |
      | missing-content-file              | reject | missing content file: ateam.tiff                         |
      | bad-account                       | reject | wrong account                                            |
      | bad-project                       | reject | wrong project                                            |
      | missing-agreement                 | reject | missing agreement info                                   |
      | multiple-agreements               | reject | multiple agreement info                                  |
      | invalid-descriptor                | reject | There is no ID/IDREF binding for IDREF 'FILE-0'          |
      | name-too-long-xxxxxxxxxxxxxxxxxxx | reject | too long (33) max is 32                                  |
      | described-hidden-file             | reject | invalid characters in file name: .hidden.txt             |
      | special-characters                | reject | invalid characters in file name: 00039'.txt              |
      | lower-level-special-characters    | reject | invalid characters in file name: Content/UF00001074'.pdf |

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
