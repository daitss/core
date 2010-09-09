Feature: packages that should reject
  Scenario Outline: packages that should reject
    Given I goto "/submit"
    When I specifically select a <package> sip to upload
    And I press "Submit"
    Then I should be at a package page
    And in the events I should see a reject event
    Examples:

    |package|
    |checksum mismatch|
    |empty|
    |bad project|
    |bad account|
    |descriptor not well formed|
    |descriptor invalid|
    |descriptor missing|
    |descriptor in lower directory|
    |missing account attribute|
    |empty account attribute|
    |missing project attribute|
    |empty project attribute|
    |descriptor named incorrectly|
    |no DAITSS agreement|
    |two DAITSS agreements|
    |content in lower directory|
    |empty directory|
    |name has more than 32 chars|
    |described hidden file|
    |undescribed hidden file|
    |special characters|
    |lower level special characters|
