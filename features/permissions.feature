Feature: permissions

  Scenario Outline: Access to pages
    Given I am logged in as an "<role>"
    When I goto "<page>"
    Then the response code should be <response>

  Examples:
      | role      | page            | response |
      | operator  | /log            | 200      |
      | operator  | /profile        | 200      |
      | operator  | /rejects        | 200      |
      | operator  | /snafus         | 200      |
      | operator  | /workspace      | 200      |
      | operator  | /stashspace     | 200      |
      | operator  | /admin/accounts | 200      |
      | operator  | /batches        | 200      |
      | operator  | /requests       | 200      |
      | affiliate | /log            | 403      |
      | affiliate | /profile        | 403      |
      | affiliate | /rejects        | 403      |
      | affiliate | /snafus         | 403      |
      | affiliate | /workspace      | 403      |
      | affiliate | /stashspace     | 403      |
      | affiliate | /admin          | 403      |
      | affiliate | /batches        | 403      |
      | affiliate | /requests       | 403      |
