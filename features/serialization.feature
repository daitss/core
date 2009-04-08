Feature: Serialization & Storage

  The AIP descriptor will be generated along with package serialization

  Scenario: AIP serialization should be a tarball
    Given a serialized AIP
    When I untar it
    Then I should have all the files
     And an AIP descriptor

  Scenario: store an AIP
    Given a serialized AIP
    When I store it
    Then it should have a storage event
     And it should be disseminatable
