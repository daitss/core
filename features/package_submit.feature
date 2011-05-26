Feature: interactive submission

  Scenario Outline: packages that should submit
    Given I goto "/packages"
    When I select "<package>" to upload
    And I press "Submit"
    Then I should be at a package page
    And in the events I should see a "<event>" event with "<note>" in the notes
    Examples:
      | package                           | event  | note |
      | haskell-nums-pdf                  | submit | |
      | mixed-case-checksums              | submit | |
      | virus                             | submit | |
      | undescribed                       | submit | undescribed file: file.txt |

  Scenario: total file count
    Given I goto "/packages"
    When I select "undescribed" to upload
    And I press "Submit"
    Then the submitted datafiles field should show 3 files
    Then the described datafiles field should show 2 files

  Scenario Outline: packages that should reject
    Given I goto "/packages"
    When I select "<package>" to upload
    And I press "Submit"
    Then I should be at a package page
    And in the events I should see a "<event>" event with "<note>" in the notes
    And there should be a reject report delivery record
    Examples:
      | package                           | event  | note |
      | checksum-mismatch                 | reject | MD5 for ateam.tiff |
      | missing-descriptor                | reject | missing descriptor |
      | missing-content-file              | reject | missing content file: ateam.tiff |
      | bad-account                       | reject | no account DNE |
      | bad-project                       | reject | no project DNE for account ACT |
      | missing-account                   | reject | missing account |
      | missing-project                   | reject | missing project |
      | missing-agreement                 | reject | missing agreement info |
      | multiple-agreements               | reject | multiple agreement info |
      | invalid-descriptor                | reject | invalid descriptor |
      | name-too-long-xxxxxxxxxxxxxxxxxxx | reject | package name contains too many characters (33) max is 32 |
      | described-hidden-file             | reject | invalid characters in file name: .hidden.txt |
      | special-characters                | reject | invalid characters in file name: 00039'.txt |
      | lower-level-special-characters    | reject | invalid characters in file name: Content/UF00001074'.pdf |
      | non-package                       | reject | cannot extract sip archive, must be a valid tar or zip file |

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
 
