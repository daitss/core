Feature: admin of users
  To be able to add, remove and modify users

  Scenario: add a new operator
    Given I goto "/admin/users"
    And I fill in the user form with:
      | id    | first_name | last_name | email             | phone    | address  |
      | snake | S.D.       | Plissken  | snake@example.com | 555-1212 | New York |
    And I uncheck "disseminate_perm"
    When I press "Create User"
    Then I should be redirected
    And there should be a user with: 
      | id    | first_name | last_name | email             | phone    | address  | permissions |
      | snake | S.D.       | Plissken  | snake@example.com | 555-1212 | New York | N/A         |
    And there should be an admin log entry:
      | user | message         |
      | foo  | new user: snake |

  Scenario: add a new contact
    Given I goto "/admin/users"
    And I fill in the user form with:
      | id    | first_name | last_name | email             | phone    | address  |
      | snake | S.D.       | Plissken  | snake@example.com | 555-1212 | New York |
    And I check "disseminate_perm"
    And I check "withdraw_perm"
    And I check "peek_perm"
    And I check "submit_perm"
    And I check "report_perm"
    And I select user type "affiliate"
    When I press "Create User"
    Then I should be redirected
    And there should be a user with: 
      | id    | first_name | last_name | email             | phone    | address  | permissions |
      | snake | S.D.       | Plissken  | snake@example.com | 555-1212 | New York | disseminate withdraw peek submit report |
    And there should be an admin log entry:
      | user | message         |
      | foo  | new user: snake |

  Scenario: remove an empty user
    Given a user "usermagee"
    And that user is empty
    And I goto "/admin/users"
    When I press "Delete" for the user
    Then I should be redirected
    And there should not be a user "usermagee"
    And there should be an admin log entry:
      | user | message               |
      | foo  | delete user: usermagee |

  Scenario: remove a non-empty user
    Given a user "usermagee"
    And that user is not empty
    And I goto "/admin/users"
    When I press "Delete" for the user
    Then the response should be NG
    Then the response contains "cannot delete a non-empty user"

  Scenario: Make admin contact
    Given a contact "admin"
    And I goto "/admin/users"
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
    And I goto "/admin/users"
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
    And I goto "/admin/users"
    When I press "Make admin contact" for the user
    Then I should be redirected
    And I goto "/admin/users"
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
    And I goto "/admin/users"
    When I press "Make technical contact" for the user
    Then I should be redirected
    And I goto "/admin/users"
    When I press "Unmake technical contact" for the user
    Then I should be redirected
    Then there should not be a user with:
      | account flags |
      | Technical Contact |
    Then there should be an admin log entry:
      | user | message               |
      | foo  | unmade tech contact: admin |

  Scenario: Update user should work
    Given I goto "/admin/users"
    And I fill in the user form with:
      | id    | first_name | last_name | email             | phone    | address  |
      | snake | S.D.       | Plissken  | snake@example.com | 555-1212 | New York |
    And I check "disseminate_perm"
    And I check "withdraw_perm"
    And I check "peek_perm"
    And I check "submit_perm"
    And I check "report_perm"
    And I select user type "affiliate"
    And I press "Create User"
    And I should be redirected
    When I goto "/admin/users/snake"
    And I fill in the user update form with:
      | first_name | last_name | email             | phone    | address  |
      | S.L.       | Flissken  | snake@foo.com     | 555-1337 | Boston   |
    And I uncheck "disseminate_perm"
    And I press "modify user"
    Then I should be redirected
    And there should be a user with: 
      | id    | first_name | last_name | email             | phone    | address  | permissions |
      | snake | S.L.       | Flissken  | snake@foo.com     | 555-1337 | Boston   | withdraw peek submit report |
    And there should be an admin log entry:
      | user | message         |
      | foo  | updated user: snake |
 
  
  Scenario: Change user password should work
    Given I goto "/admin/users"
    And I fill in the user form with:
      | id    | first_name | last_name | email             | phone    | address  | password |
      | snake | S.D.       | Plissken  | snake@example.com | 555-1212 | New York | foo |
    And I press "Create User"
    And I should be redirected
    When I goto "/admin/users/snake"
    And I fill in the user password form with:
      | old_password | new_password | new_password_confirm |
      | foo | bar | bar |
    And I press "change password"
    Then I should be redirected
    And user "snake" should authenticate with password "bar"

  Scenario: Wrong old password should result in 400
    Given I goto "/admin/users"
    And I fill in the user form with:
      | id    | first_name | last_name | email             | phone    | address  | password |
      | snake | S.D.       | Plissken  | snake@example.com | 555-1212 | New York | foo |
    And I press "Create User"
    And I should be redirected
    When I goto "/admin/users/snake"
    And I fill in the user password form with:
      | old_password | new_password | new_password_confirm |
      | bar | foo | foo |
    And I press "change password"
    Then the response code should be 400

  Scenario: Mismatched new password should result in 400
    Given I goto "/admin/users"
    And I fill in the user form with:
      | id    | first_name | last_name | email             | phone    | address  | password |
      | snake | S.D.       | Plissken  | snake@example.com | 555-1212 | New York | foo |
    And I press "Create User"
    And I should be redirected
    When I goto "/admin/users/snake"
    And I fill in the user password form with:
      | old_password | new_password | new_password_confirm |
      | foo | foo | fod |
    And I press "change password"
    Then the response code should be 400
