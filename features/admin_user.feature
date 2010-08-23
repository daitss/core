Feature: admin of users
  To be able to add & remove users

  Scenario: add a new user
    Given I goto "/admin"
    And I fill in the user form with:
      | username | first_name | last_name | email             | phone    | address  |
      | snake    | S.D.       | Plissken  | snake@example.com | 555-1212 | New York |
    When I press "Create User"
    Then there should be a user with:
      | username | first_name | last_name | email             | phone    | address  |
      | snake    | S.D.       | Plissken  | snake@example.com | 555-1212 | New York |
    And there should be an admin log entry:
      | user | message         |
      | foo  | new user: snake |

  Scenario: remove an empty user
    Given a user named "usermagee"
    And that user is empty
    And I goto "/admin"
    When I press "Delete" for the user
    Then there should not be a user named "usermagee"
    And there should be an admin log entry:
      | user | message             |
      | foo  | delete user: usermagee |

  Scenario: remove a non-empty user
    Given a user named "usermagee"
    And that user is not empty
    And I goto "/admin"
    When I press "Delete" for the user
    Then the response should be NG
    Then the response contains "cannot delete a non-empty user"
