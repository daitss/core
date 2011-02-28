Feature: interactive submission

  Background:
    Given I am logged in as an affiliate of "ACT"
    And account "ACT" has a project "PRJ"

  Scenario Outline: packages that should reject or submit
    Given I go to the packages page
    When I attach the sip "<package>" to "sip"
    And I press "Submit"
    #Then I should see "<action>" within ".notice"
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
    Given I goto "/packages"
    When I select "haskell-nums-pdf" to upload
    And I fill in "note" with "a note"
    And I press "Submit"
    Then I should be at a package page
    And in the events I should see a "submit" event with "a note" in the notes

  Scenario: submission to batch
    Given I goto "/packages"
    When I select "haskell-nums-pdf" to upload
    And I fill in "batch_id" with "mybatch"
    And I press "Submit"
    And I should be redirected
    And I goto "/batches"
    And I click on "mybatch"
    Then I should have a batch containing
      |haskell-nums-pdf|

  Scenario: ignore note if not filled in
    Given I goto "/packages"
    When I select "haskell-nums-pdf" to upload
    And I press "Submit"
    Then I should be at a package page
    And in the events I should not see a "submit" event with "note" in the notes

  Scenario: ignore batch if not filled in
    Given I goto "/packages"
    When I select "haskell-nums-pdf" to upload
    And I press "Submit"
    And I should be redirected
    And I goto "/batches"
    Then I should not have batch "batch name"
