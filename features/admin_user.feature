Feature: admin of users
  To be able to add & remove users

  Scenario: add a new user
    Given I goto "/admin"
    And I fill in the user form with:
      | id    | first_name | last_name | email             | phone    | address  |
      | snake | S.D.       | Plissken  | snake@example.com | 555-1212 | New York |
    When I press "Create User"
    Then I should be redirected
    And there should be a user with:
      | id    | first_name | last_name | email             | phone    | address  |
      | snake | S.D.       | Plissken  | snake@example.com | 555-1212 | New York |
    And there should be an admin log entry:
      | user | message         |
      | foo  | new user: snake |

  Scenario: remove an empty user
    Given a user "usermagee"
    And that user is empty
    And I goto "/admin"
    When I press "Delete" for the user
    Then I should be redirected
    And there should not be a user "usermagee"
    And there should be an admin log entry:
      | user | message               |
      | foo  | delete user: usermagee |

  Scenario: remove a non-empty user
    Given a user "usermagee"
    And that user is not empty
    And I goto "/admin"
    When I press "Delete" for the user
    Then the response should be NG
    Then the response contains "cannot delete a non-empty user"

  Scenario: Make admin contact
    Given a contact "admin"
    And I goto "/admin"
    When I press "Make admin contact" for the user
    Then I should be redirected
    Then there should be a user with:
      | account flags |
      | Admin Contact |
    Then there should be an admin log entry:
      | user | message               |
      | foo  | made admin contact: admin |

  Scenario: Make tech contact
    Given a contact "admin"
    And I goto "/admin"
    When I press "Make technical contact" for the user
    Then I should be redirected
    Then there should be a user with:
      | account flags |
      | Technical Contact |
    Then there should be an admin log entry:
      | user | message               |
      | foo  | made tech contact: admin |

  Scenario: Unmake admin contact
    Given a contact "admin"
    And I goto "/admin"
    When I press "Make admin contact" for the user
    Then I should be redirected
    And I goto "/admin"
    When I press "Unmake admin contact" for the user
    Then I should be redirected
    Then there should not be a user with:
      | account flags |
      | Admin Contact |
    Then there should be an admin log entry:
      | user | message               |
      | foo  | unmade admin contact: admin |

  Scenario: Unmake tech contact
    Given a contact "admin"
    And I goto "/admin"
    When I press "Make technical contact" for the user
    Then I should be redirected
    And I goto "/admin"
    When I press "Unmake technical contact" for the user
    Then I should be redirected
    Then there should not be a user with:
      | account flags |
      | Technical Contact |
    Then there should be an admin log entry:
      | user | message               |
      | foo  | unmade tech contact: admin |
