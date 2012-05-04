Feature: interactive submission

  Scenario Outline: packages that should submit
    Given I goto "/packages"
    When I select "<package>" to upload
    And I press "Submit"
    Then I should be at a package page
    And in the events I should see a "<event>" event with "<note>" in the notes
    Examples:
      | package                           | event  | note |
      | lower-level-special-characters    | submit | |
      | haskell-nums-pdf                  | submit | |
      | FDCONTENTTILDE                    | submit | |
      | FDCONTENTLEFTPAREN                | submit | |
      | FDCONTENTRIGHTPAREN               | submit | |
      | FDCONTENTASTERISK                 | submit | |
      | FDCONTENTSINGLEQUOTE              | submit | |
      | percent20_in_href                 | submit | |
      | FD A                              | submit | |                                      
      | FD!A                              | submit | |
      | FD*A                              | submit | |
      | FD(A                              | submit | |
      | FD)A                              | submit | |
      | FD'A                              | submit | |
      | FD~A                              | submit | |
      | FDCONTENTSPACE                    | submit | |
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
      | non-package                       | reject |  cannot extract sip archive, must be a valid tar or zip file containing directory with sip files |
      | FD"A                              | reject | invalid characters in file name: FD"A.zip |
      | FD#A                              | reject | invalid characters in file name: FD#A.zip |
      | FD$A                              | reject | invalid characters in file name: FD$A.zip |
      | FD%A                              | reject | invalid characters in file name: FD%A.zip |
      | FD&A                              | reject | invalid characters in file name: FD&A.zip |
      | FD+A                              | reject | invalid characters in file name: FD+A.zip |
      | FD,A                              | reject | invalid characters in file name: FD,A.zip |
      | FD?A                              | reject | invalid characters in file name: FD?A.zip |
      | FD:A                              | reject | invalid characters in file name: FD:A.zip |
      | FD;A                              | reject | invalid characters in file name: FD;A.zip |
      | FD<A                              | reject | invalid characters in file name: FD<A.zip |
      | FD=A                              | reject | invalid characters in file name: FD=A.zip |
      | FD>A                              | reject | invalid characters in file name: FD>A.zip |
      | FD?A                              | reject | invalid characters in file name: FD?A.zip |
      | FD@A                              | reject | invalid characters in file name: FD@A.zip |
      | FD[A                              | reject | invalid characters in file name: FD[A.zip |
      | FD\A                              | reject | is not a package                          |
      | FD]A                              | reject | invalid characters in file name: FD]A.zip |
      | FD^A                              | reject | invalid characters in file name: FD^A.zip |
      | FD`A                              | reject | invalid characters in file name: FD`A.zip |
      | FDCONTENTLEFTBRACKET              | reject | invalid descriptor  |
      | FDCONTENTPERCENT                  | reject | invalid descriptor  |
      | FDCONTENTPOUND                    | reject | invalid characters in file name: small#test.pdf |
      | FDCONTENTATSIGN                   | reject | invalid characters in file name: small@test.pdf |
      | FDCONTENTSPACETWO                 | reject | invalid characters in file name: small  test.pdf |
      | FDCONTENTAMPER                    | reject | invalid characters in file name: FDCONTENTAMPER.xml    |
      | FDCONTENTDOUBLEQUOTE              | reject | invalid characters in file name: FDCONTENTDOUBLEQUOTE.xml  |
      | FDCONTENTMORETHAN                 | reject | invalid characters in file name: small>test.pdf |
      | FDCONTENTPIPE                     | reject | invalid characters in file name: small                     |
      | FDCONTENTBACKSLASH                | reject | missing descriptor                                 |
      | FDCONTENTBACKTICK                 | reject | invalid characters in file name: small`test.pdf    |
      | FDCONTENTCARET                    | reject | invalid characters in file name: small^test.pdf    |
      | FDCONTENTLEFTBRACKET              | reject | invalid descriptor  |
      | FDCONTENTRIGHTBRACKET             | reject | invalid descriptor  |
      | FDCONTENTLEFTCURLY                | reject | invalid characters in file name: small{test.pdf    |
      | FDCONTENTRIGHTCURLY               | reject | invalid characters in file name: small}test.pdf    |
      | FDCONTENTCOLON                    | reject | invalid characters in file name: small:test.pdf    |
      | FDCONTENTCOMMA                    | reject | invalid characters in file name: small,test.pdf    |
      | FDCONTENTDOLLAR                   | reject | invalid characters in file name: small$test.pdf    |
      | FDCONTENTEQUAL                    | reject | invalid characters in file name: small=test.pdf    |
      | FDCONTENTPLUS                     | reject | invalid characters in file name: small+test.pdf    |
      | FDCONTENTQUESTION                 | reject | invalid characters in file name: small?test.pdf    |
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
      | lower-level-special-characters-ng | reject | invalid characters in file name: Content/UF00001074?.pdf |
     

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
 
