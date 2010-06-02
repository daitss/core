Feature: Packages that should ingest correctly under DAITSS 2

  Scenario Outline: The submission and ingest of a package with a copy of itself inside itself
    Given an archive operator
    And a workspace
    And a <package> package
    When submission is run on that package
    And ingest is run on that package
    Then the package is present in the AIP store once
    And there is an operations event for the submission
    And there is an operations event for the ingest
      Examples:

      |package|
      |35 content files|
      |1000 content files|
      |10000 content files|
      |duplicate content files by checksum|
      |empty content file|
      |content not described|
      |copy of descriptor|
      |ISSN Entity ID|
      |OJBID different than package name|
      |no checksums for content files|
      |package name different than ID in metsHDr|
      |mdRef element in descriptive metadata|
      |empty lower directory not listed|
      |more than one lower level directory|
      |descriptor in lower directory|

