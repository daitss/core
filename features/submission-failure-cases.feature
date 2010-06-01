Feature: Cases where packages fail to submit

  Scenario Outline: Submission failures which should result in a record in the sip table and an operations event
    Given an archive <user>
    And a workspace
    And a <package> package
    When submission is attempted on that package
    Then submission fails
    And there is an operations event for the submission
    Examples:
    |user|package|
    |operator|checksum mismatch|
    |operator|empty|
    |operator|bad project|
    |operator|bad account|
    |operator|descriptor not well formed|
    |operator|descriptor invalid|
    |operator|descriptor missing|
	|operator|descriptor in lower directory|
    |operator|missing account attribute|
	|operator|missing project attribute
    |operator|empty account attribute|
	|operator|empty project attribute|
	|operator|descriptor present but named incorrectly|
	|operator|no DAITSS agreement|
	|operator|two DAITSS argeements|
	|operator|content in lower directory than listed|
	|operator|empty directory|
	|operator|name with more than 32 characters|
	|operator|described hidden file|
	|operator|undescribed hidden file|
	|operator|content files with special characters|
	|operator|lower level content files with special characters|
	|operator|only a descriptor file|
	|operator|only a content file|
	|operator|more than one validation problem|
	|operator|special character in directory name
    |operator|mxf descriptor|



  Scenario Outline: Submission failures which should not result in a record in the sip table and an operations event
    Given an archive <user>
    And a workspace
    And a <package> package
    When submission is attempted on that package
    Then submission fails
    Examples:
    |user|package|
    |invalid user|good|
    |unauthorized contact|good|
