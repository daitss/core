Feature: populate an aip containing a document 

Scenario: an aip containing a pdf with many images
  Given an aip containing a pdf with many bitstream
  When populating the aip
  Then I should have a datafile named etd.pdf
  And I should have 19 image bitstreams

Scenario: an aip containing a pdf with embedded fonts
	Given an aip containing a pdf with embedded fonts
	When populating the aip
	Then I should see E00000000_000000 intentitiy record
	And all E00000000_000000 representations should exist
	And I should have a datafile named files/Haskell98numbers.pdf
	And I should have a document with embedded fonts
