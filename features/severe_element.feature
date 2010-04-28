Feature: populate an aip containing objects with severe_element

Scenario: an aip containing a pdf with inhibitor
  Given an aip containing a pdf with inhibitor
  When populating the aip
  Then I should have a datafile named pwprotected.pdf
  And it should have an inhibitor

Scenario: an aip containing a pdf with anomaly
  Given an aip containing a pdf with anomaly
  When populating the aip
  Then I should have a datafile named pwprotected.pdf
  And it should have an anomaly

Scenario: an aip containing a xml with broken links
  Given an aip containing a xml with broken links
  When populating the aip
  Then I should have a datafile named ateam.xml
  And it should have a broken link

