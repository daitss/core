# test harness for pdf/a validation and conversion.  These test harness will only
# pass if pdfapilot is setup and both the description service and transform server are setup
# to use pdfapilot

Feature: ingest a package with pdf/a conversion and validation

  Scenario Outline: ingest a package with a pdf normalized successfully
    Given I submit "<sip>"
    When I click on "ingesting"
    And I choose "start"
    And I press "Update"
    And I should be redirected
    And I wait for it to finish
    Then I should be redirected
    And I should be at the package page
    And there should be an "normalize" premis-event on "ARCHIVE" file
    And the outcome should be "success"
	Examples:
	  | sip              |
	  | ateam            |
	
  Scenario Outline: ingest a package with a pdf normalization failure
	Given I submit "<sip>"
	  When I click on "ingesting"
	  And I choose "start"
	  And I press "Update"
      And I should be redirected
	  And I wait for it to finish
	  Then I should be redirected
	  And I should be at the package page
	  And there should be an "ingest finished" event
	  And there should be an "normalize" premis-event on "ARCHIVE" file
	  And the outcome should be "failure"
	  And the outcome_details should be "<error>Embed missing fonts:Tahoma-Bold</error><error>Convert to PDF/A-1b</error><error>Remove additional encoding entries in cmap of symbolic TrueType fonts</error>" 
	  Examples:
	    | sip              |
	    | ateam-bad-pdf    |

  Scenario Outline: ingest a package with a valid pdf/a 
	Given I submit "<sip>"
	  When I click on "ingesting"
      And I choose "start"
      And I press "Update"
	  And I should be redirected
	  And I wait for it to finish
	  Then I should be redirected
	  And I should be at the package page
	  And there should be an "describe" premis-event for "sip-files/valid.pdf"
	  And the event_details should be "Well-Formed and valid"
	  Examples:
	    | sip              |
	    | valid_a1b        |
	    | valid_a2b        |	

  Scenario Outline: ingest a package with an invalid pdf/a 
	Given I submit "<sip>"
	  When I click on "ingesting"
      And I choose "start"
      And I press "Update"
	  And I should be redirected
	  And I wait for it to finish
	  Then I should be redirected
	  And I should be at the package page
	  And there should be an "describe" premis-event for "sip-files/invalid.pdf"
	  And the event_details should be "Well-Formed, but not valid"
	  And the outcome_details should be "<anomaly>pdfaPilot:PDF/A entry missing</anomaly><anomaly>pdfaPilot:Syntax problem: Indirect object “obj” keyword not followed by an EOL marker</anomaly><anomaly>pdfaPilot:XMP property not predefined and no extension schema present</anomaly>"
	  And there should have anomalies for "sip-files/invalid.pdf"
	  Examples:
	    | sip              |
	    | invalid_a1b      |
