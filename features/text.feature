Feature: populate an aip containing text
Scenario: an aip containing a xml
	Given an aip containing a xml
	When populating the aip
	Then I should see E00000000_000000 intentitiy record
	And all E00000000_000000 representations should exist
	And I should have a datafile named files/haskell-nums-pdf.xml
	And the datafile should be associated a text stream
	