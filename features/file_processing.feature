Feature: Process each content file in the package

  Every existing file and every produced file must be processed.

  Any non systemic errors in processing will not hinder the ingest
  of the package.

  Scenario: a simple file
    Given a tiff file in an aip
    When I process it
    Then it should have a description event
    And a action plan event
    And no transformation event
    And there should be 0 produced files

  Scenario: a migratable file
    Given a jpeg file in an aip
    When I process it
    Then it should have a description event
    And a action plan event
    And a transformation event
    And there should be 1 produced files
    And there should be a relationship between them

  Scenario: a file that fails description
    Given a file in an aip
    When I process it
    Then it should have a failed description event
    And a action plan event
    And no transformation event
    And there should be 0 produced files

  Scenario: a file that fails migration
    Given a file in an aip
    When I process it
    Then it should have a description event
    And a action plan event
    And a failed transformation event
    And there should be 0 produced files

  Scenario: a migrated file that is not of the expected format
    Given a poorly migrated file with an expected format
    When I process it
    Then it should be deleted
    And the source file should have a failed migration event
