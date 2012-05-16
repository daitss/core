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
      | non-package                       | reject |  Cannot extract sip archive, must be a valid tar or zip file containing directory with sip files |
      | ateam_rar_as_zip                  | reject |  Cannot extract sip archive, must be a valid tar or zip file containing directory with sip files |
      | non-package                       | reject |  Cannot extract sip archive, must be a valid tar or zip file containing directory with sip files |
      | FD"A                              | reject | Invalid character in package name: FD"A.zip |
      | FD#A                              | reject | Invalid character in package name: FD#A.zip |
      | FD$A                              | reject | Invalid character in package name: FD$A.zip |
      | FD%A                              | reject | Invalid character in package name: FD%A.zip |
      | FD&A                              | reject | Invalid character in package name: FD&A.zip |
      | FD+A                              | reject | Invalid character in package name: FD+A.zip |
      | FD,A                              | reject | Invalid character in package name: FD,A.zip |
      | FD?A                              | reject | Invalid character in package name: FD?A.zip |
      | FD:A                              | reject | Invalid character in package name: FD:A.zip |
      | FD;A                              | reject | Invalid character in package name: FD;A.zip |
      | FD<A                              | reject | Invalid character in package name: FD<A.zip |
      | FD=A                              | reject | Invalid character in package name: FD=A.zip |
      | FD>A                              | reject | Invalid character in package name: FD>A.zip |
      | FD?A                              | reject | Invalid character in package name: FD?A.zip |
      | FD@A                              | reject | Invalid character in package name: FD@A.zip |
      | FD[A                              | reject | Invalid character in package name: FD[A.zip |
      | FD\A                              | reject | is not a package                          |
      | FD]A                              | reject | Invalid character in package name: FD]A.zip |
      | FD^A                              | reject | Invalid character in package name: FD^A.zip |
      | FD`A                              | reject | Invalid character in package name: FD`A.zip |
      | FDCONTENTPERCENT                  | reject | Invalid SIP descriptor  |
      | FDCONTENTPOUND                    | reject | Invalid character in file name: small#test.pdf |
      | FDCONTENTATSIGN                   | reject | Invalid character in file name: small@test.pdf |
      | FDCONTENTSPACETWO                 | reject | Invalid character in file name: small  test.pdf |
      | FDCONTENTAMPER                    | reject | Invalid character in file name: FDCONTENTAMPER.xml    |
      | FDCONTENTDOUBLEQUOTE              | reject | Invalid character in file name: FDCONTENTDOUBLEQUOTE.xml  |
      | FDCONTENTMORETHAN                 | reject | Invalid character in file name: small>test.pdf |
      | FDCONTENTPIPE                     | reject | Invalid character in file name: small                     |
      | FDCONTENTBACKSLASH                | reject | missing descriptor                                 |
      | FDCONTENTBACKTICK                 | reject | Invalid character in file name: small`test.pdf    |
      | FDCONTENTCARET                    | reject | Invalid character in file name: small^test.pdf    |
      | FDCONTENTLEFTBRACKET              | reject | Invalid SIP descriptor  |
      | FDCONTENTRIGHTBRACKET             | reject | Invalid SIP descriptor  |
      | FDCONTENTLEFTCURLY                | reject | Invalid character in file name: small{test.pdf    |
      | FDCONTENTRIGHTCURLY               | reject | Invalid character in file name: small}test.pdf    |
      | FDCONTENTCOLON                    | reject | Invalid character in file name: small:test.pdf    |
      | FDCONTENTCOMMA                    | reject | Invalid character in file name: small,test.pdf    |
      | FDCONTENTDOLLAR                   | reject | Invalid character in file name: small$test.pdf    |
      | FDCONTENTEQUAL                    | reject | Invalid character in file name: small=test.pdf    |
      | FDCONTENTPLUS                     | reject | Invalid character in file name: small+test.pdf    |
      | FDCONTENTQUESTION                 | reject | Invalid character in file name: small?test.pdf    |
      | checksum-mismatch                 | reject | MD5 for ateam.tiff |
      | missing-descriptor                | reject | missing descriptor |
      | missing-content-file              | reject | Cannot find described content file: ateam.tiff |
      | bad-account                       | reject | no account DNE |
      | bad-project                       | reject | no project DNE for account ACT |
      | missing-account                   | reject | missing account |
      | missing-project                   | reject | missing project |
      | missing-agreement                 | reject | missing agreement info |
      | multiple-agreements               | reject | multiple agreement info |
      | invalid-descriptor                | reject | Invalid SIP descriptor |
      | name-too-long-xxxxxxxxxxxxxxxxxxx | reject | Package name contains too many characters (33) max is 32 |
      | described-hidden-file             | reject | Invalid character in file name: .hidden.txt |
      | lower-level-special-characters-ng | reject | Invalid character in file name: Content/UF00001074?.pdf |
     

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
 
