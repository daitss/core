Feature: admin of projects
  To be able to add & remove projects

  Scenario: add a new project
    Given I goto "/admin/projects"
    And a account "ACTPRJ"
    And I fill in the project form with:
      | id  | description | account_id |
      | ADD | add test    | ACTPRJ     |
    When I press "Create project"
    Then I should be redirected
    And there should be an project with:
      | id  | description | account_id |
      | ADD | add test    | ACTPRJ     |
    And there should be an admin log entry:
      | user | message          |
      | foo  | new project: ADD |

  Scenario: remove an empty project
    Given a project "RM"
    And that project is empty
    And I goto "/admin/projects"
    When I press "Delete" for the project
    Then I should be redirected
    And there should not be a project "RM"
    And there should be an admin log entry:
      | user | message            |
      | foo  | delete project: RM |

  Scenario: remove a non-empty project
    Given a project "RMNE"
    And that project is not empty
    And I goto "/admin/projects"
    When I press "Delete" for the project
    Then the response should be NG
    Then the response contains "cannot delete a non-empty project"

  Scenario: modify project 
    Given I goto "/admin/projects"
    When I click on "modify project"
    And I fill in the project update form with:
      | description | 
      | updated  | 
    And I press "modify project"
    Then I should be redirected
    And there should be an project with:
      | id | description | account_id |
      | PRJ | updated | ACT |
    And there should be an admin log entry:
      | user | message          |
      | foo  | updated project: PRJ (ACT) |

  Scenario: should get 404 if you try to modify non-existant account 
    Given I goto "/admin/accounts/ACT/FOO"
    Then the response code should be 404

  Scenario: should get 400 if attempting to create project that already exists
    Given I goto "/admin/projects"
    And a account "ACTPRJ"
    And I fill in the project form with:
      | id  | description | account_id |
      | default | add test    | ACTPRJ     |
    When I press "Create project"
    Then the response code should be 400
 
