Feature: show information about the wip

  Scenario: show all the processing steps of a wip
    Given a workspace with 1 wip
    When I goto its wip page
    Then I should see the progress section
    And in the progress section I should see a field for "virus check"
    And in the progress section I should see a field for "describe original files"
    And in the progress section I should see a field for "migrate original files"
    And in the progress section I should see a field for "normalize original files"
    And in the progress section I should see a field for "describe transformed files"
    And in the progress section I should see a field for "xml resolution"
    And in the progress section I should see a field for "assemble descriptor"
    And in the progress section I should see a field for "save aip"
