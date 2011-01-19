Feature: admin of projects
  To be able to add & remove projects

  Scenario: add a new project
    Given I goto "/admin/projects"
    And a account "ACTPRJ"
    And I fill in the project form with:
      | id  | description | account_id |
      | ADD | add test    | ACTPRJ     |
    When I press "Create Project"
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
