Feature: Start submissions
  In order ingest submissions
  As an operator
  I want to start all sips in the workspace that need ingesting

  Scenario: start all packages
    Given a workspace with many sips
    When I type boss start
    Then They should show up in the list
