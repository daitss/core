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
  
  Scenario: Dissemination request attempted from user with different account
    Given an archive contact from a different account
    And a workspace
    And an ingested good package
    When a dissemination request is attempted for that package
    Then the request is denied

  Scenario: Withdrawal request is queued and then dequeued to workspace without authorization (operator)
    Given an archive operator
    And a workspace
    And an ingested good package
    When a withdrawal request is submitted for that package
    And the workspace is polled
    Then there is not a withdrawal wip in the workspace
    And the request is queued
    And there is an operations event for the withdrawal request queuing
    And there is not an operations event for the withdrawal request dequeuing

  Scenario: Withdrawal request is queued and then dequeued to workspace without authorization (contact)
    Given an archive contact
    And a workspace
    And an ingested good package
    When a withdrawal request is submitted for that package
    And the workspace is polled
    Then there is not a withdrawal wip in the workspace
    And the request is queued
    And there is an operations event for the withdrawal request queuing
    And there is not an operations event for the withdrawal request dequeuing

  Scenario: Withdrawal request is queued by an operator, authorized and then dequeued to workspace
    Given an archive operator
    And a workspace
    And an ingested good package
    When a withdrawal request is submitted for that package
    And that request is authorized by another operator
    And the workspace is polled
    Then there is a withdrawal wip in the workspace
    And the request is not queued
    And there is an operations event for the withdrawal request queuing
    And there is an operations event for the withdrawal request dequeuing
    And there is an operations event for the withdrawal request authorization
  
  Scenario: Withdrawal request is queued by a contact, authorized and then dequeued to workspace
    Given an archive contact
    And a workspace
    And an ingested good package
    When a withdrawal request is submitted for that package
    And that request is authorized by another operator
    And the workspace is polled
    Then there is a withdrawal wip in the workspace
    And the request is not queued
    And there is an operations event for the withdrawal request queuing
    And there is an operations event for the withdrawal request dequeuing
    And there is an operations event for the withdrawal request authorization

  Scenario: Withdrawal request is queued, and authorization is attempted by a contact
    Given an archive contact
    And a workspace
    And an ingested good package
    When a withdrawal request is submitted for that package
    And that request is authorized by the request submitter
    Then the request is not authorized

  Scenario: Withdrawal request is queued by an operator and authorization is attempted by the same operator
    Given an archive operator
    And a workspace
    And an ingested good package
    When a withdrawal request is submitted for that package
    And that request is authorized by the request submitter
    Then the request is not authorized

  Scenario: Withdrawal request queued (operator)
    Given an archive operator
    And a workspace
    And an ingested good package
    When a withdrawal request is submitted for that package
    Then the request is queued
    And there is an operations event for the withdrawal request queuing

  Scenario: Withdrawal request queued (contact)
    Given an archive contact
    And a workspace
    And an ingested good package
    When a withdrawal request is submitted for that package
    Then the request is queued
    And there is an operations event for the withdrawal request queuing

  Scenario: Withdrawal request deletion (operator)
    Given an archive operator
    And a workspace
    And an ingested good package
    When a withdrawal request is submitted for that package
    And a withdrawal request is deleted for that package
    Then the request is not queued
    And there is an operations event for the withdrawal request queuing
    And there is an operations event for the withdrawal request deletion

  Scenario: Withdrawal request deletion (contact)
    Given an archive contact
    And a workspace
    And an ingested good package
    When a withdrawal request is submitted for that package
    And a withdrawal request is deleted for that package
    Then the request is not queued
    And there is an operations event for the withdrawal request queuing
    And there is an operations event for the withdrawal request deletion

  Scenario: Withdrawal request attempted from unauthorized user
    Given an archive unauthorized contact 
    And a workspace
    And an ingested good package
    When a withdrawal request is attempted for that package
    Then the request is denied

  Scenario: Withdrawal request attempted from invalid user
    Given an archive invalid user
    And a workspace
    And an ingested good package
    When a withdrawal request is attempted for that package
    Then the request is denied
  
  Scenario: Withdrawal request attempted from user with different account
    Given an archive contact from a different account
    And a workspace
    And an ingested good package
    When a withdrawal request is attempted for that package
    Then the request is denied

  Scenario: Peek request is queued and then dequeued to workspace (operator)
    Given an archive operator
    And a workspace
    And an ingested good package
    When a peek request is submitted for that package
    And the workspace is polled
    Then there is a peek wip in the workspace
    And the request is not queued
    And there is an operations event for the peek request queuing
    And there is an operations event for the peek request dequeuing

  Scenario: Peek request is queued and then dequeued to workspace (contact)
    Given an archive contact
    And a workspace
    And an ingested good package
    When a peek request is submitted for that package
    And the workspace is polled
    Then there is a peek wip in the workspace
    And the request is not queued
    And there is an operations event for the peek request queuing
    And there is an operations event for the peek request dequeuing

  Scenario: Peek request queued (operator)
    Given an archive operator
    And a workspace
    And an ingested good package
    When a peek request is submitted for that package
    Then the request is queued
    And there is an operations event for the peek request queuing

  Scenario: Peek request queued (contact)
    Given an archive contact
    And a workspace
    And an ingested good package
    When a peek request is submitted for that package
    Then the request is queued
    And there is an operations event for the peek request queuing

  Scenario: Peek request deletion (operator)
    Given an archive operator
    And a workspace
    And an ingested good package
    When a peek request is submitted for that package
    And a peek request is deleted for that package
    Then the request is not queued
    And there is an operations event for the peek request queuing
    And there is an operations event for the peek request deletion

  Scenario: Peek request deletion (contact)
    Given an archive contact
    And a workspace
    And an ingested good package
    When a peek request is submitted for that package
    And a peek request is deleted for that package
    Then the request is not queued
    And there is an operations event for the peek request queuing
    And there is an operations event for the peek request deletion

  Scenario: Peek request attempted from unauthorized user
    Given an archive unauthorized contact 
    And a workspace
    And an ingested good package
    When a peek request is attempted for that package
    Then the request is denied

  Scenario: Peek request attempted from invalid user
    Given an archive invalid user
    And a workspace
    And an ingested good package
    When a peek request is attempted for that package
    Then the request is denied
  
  Scenario: Peek request attempted from user with different account
    Given an archive contact from a different account
    And a workspace
    And an ingested good package
    When a peek request is attempted for that package
    Then the request is denied


