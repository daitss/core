Feature: admin of projects
  To be able to add & remove projects

  Scenario: add a new project
    Given I goto "/admin"
    And a account coded "ACTPRJ"
    And I fill in the project form with:
      | code | name     | account |
      | ADD  | add test | ACTPRJ  |
    When I press "Create Project"
    Then there should be an project with:
      | code | name     | account |
      | ADD  | add test | ACTPRJ  |

  Scenario: remove an empty project
    Given a project named "test rm"
    And that project is empty
    And I goto "/admin"
    When I press "Delete" for the project
    Then there should not be a project named "test rm"

  Scenario: remove a non-empty project
    Given a project named "test rm non empty"
    And that project is not empty
    And I goto "/admin"
    When I press "Delete" for the project
    Then the response should be NG
    Then the response contains "cannot delete a non-empty project"
