Feature: download daitss 2 report stylesheet

  Scenario: download stylesheet
    Given I goto "/daitss_report_xhtml.xsl"
    Then the response should be OK


