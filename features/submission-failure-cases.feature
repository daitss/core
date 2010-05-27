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
    |operator|missing account and project attribute|
    |operator|empty account and project attribute|
    |operator|mxf descriptor|
    |operator|toc descriptor|
    |operator|descriptor present by named incorrectly|


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
