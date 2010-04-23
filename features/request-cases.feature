Feature: Package request use cases

  Scenario: Dissemination request is queued and then dequeued to workspace (operator)
    Given an archive operator
    And a workspace
    And an ingested good package
    When a dissemination request is submitted for that package
    And the workspace is polled
    Then there is a dissemination wip in the workspace
    And the request is not queued
    And there is an operations event for the dissemination request queuing
    And there is an operations event for the dissemination request dequeuing

  Scenario: Dissemination request is queued and then dequeued to workspace (contact)
    Given an archive contact
    And a workspace
    And an ingested good package
    When a dissemination request is submitted for that package
    And the workspace is polled
    Then there is a dissemination wip in the workspace
    And the request is not queued
    And there is an operations event for the dissemination request queuing
    And there is an operations event for the dissemination request dequeuing

  Scenario: Dissemination request queued (operator)
    Given an archive operator
    And a workspace
    And an ingested good package
    When a dissemination request is submitted for that package
    Then the request is queued
    And there is an operations event for the dissemination request queuing

  Scenario: Dissemination request queued (contact)
    Given an archive contact
    And a workspace
    And an ingested good package
    When a dissemination request is submitted for that package
    Then the request is queued
    And there is an operations event for the dissemination request queuing

  Scenario: Dissemination request deletion (operator)
    Given an archive operator
    And a workspace
    And an ingested good package
    When a dissemination request is submitted for that package
    And a dissemination request is deleted for that package
    Then the request is not queued
    And there is an operations event for the dissemination request queuing
    And there is an operations event for the dissemination request deletion

  Scenario: Dissemination request deletion (contact)
    Given an archive contact
    And a workspace
    And an ingested good package
    When a dissemination request is submitted for that package
    And a dissemination request is deleted for that package
    Then the request is not queued
    And there is an operations event for the dissemination request queuing
    And there is an operations event for the dissemination request deletion

  Scenario: Dissemination request attempted from unauthorized user
    Given an archive unauthorized contact 
    And a workspace
    And an ingested good package
    When a dissemination request is attempted for that package
    Then the request is denied

  Scenario: Dissemination request attempted from invalid user
    Given an archive invalid user
    And a workspace
    And an ingested good package
    When a dissemination request is attempted for that package
    Then the request is denied


