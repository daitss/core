Feature: Cases where packages fail to submit

  Scenario Outline: Submission failures which should result in a record in the sip table and an operations event
    Given an archive <user>
    And a workspace
    And a <package> package
    When submission is attempted on that package
    Then submission fails
    And there is an operations event for the submission
	And the operations event denotes failure
    And the operations event notes field shows details for a <failure type>
    Examples:
	
    |user|package|failure type|
    |operator|checksum mismatch|checksum mismatch|
    |operator|empty| empty|
    |operator|bad project|bad project|
    |operator|bad account|bad account|
    |operator|descriptor not well formed|descriptor not well formed|
    |operator|descriptor invalid|descriptor invalid|
    |operator|descriptor missing|descriptor missing|
    |operator|descriptor in lower directory|descriptor in lower directory|
    |operator|missing account attribute|missing account attribute|
    |operator|missing project attribute|missing project attribute|
    |operator|empty account attribute|empty account attribute|
    |operator|empty project attribute|empty project attribute|
    |operator|descriptor present but named incorrectly|descriptor present but named incorrectly|
    |operator|no DAITSS agreement|no DAITSS agreement|
    |operator|two DAITSS agreements|two DAITSS agreements|
    |operator|content in lower directory than listed|content in lower directory than listed|
    |operator|empty directory|empty directory|
    |operator|name with more than 32 characters|name with more than 32 characters|
    |operator|described hidden file|described hidden file|
    |operator|undescribed hidden file|undescribed hidden file|
    |operator|content files with special characters|content files with special characters|
    |operator|lower level content files with special characters|lower level content files with special characters|
    |operator|only a descriptor file|only a descriptor file|
    |operator|only a content file|only a content file|
    |operator|more than one validation problem|more than one validation problem|
    |operator|special character in directory name|special characters in directory name|
    |operator|mxf descriptor|mxf descriptor|
    |operator|toc descriptor|toc descriptor|


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
