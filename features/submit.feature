Feature: interactive submission

  Scenario Outline: packages that should reject or submit
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
      | checksum-mismatch                 | reject | MD5 for ateam.tiff - expected: 905ae75bc4595521e350564c90a56d28; computed 805ae75bc4595521e350564c90a56d28 |
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
      | described-hidden-file             | reject | per installation? |
      | undescribed-hidden-file           | reject | per installation? |
      | special-characters                | reject | per installation? |
      | lower-level-special-characters    | reject | per installation? |
