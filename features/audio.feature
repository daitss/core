Feature: populate an aip containing an audio file 
Scenario: an aip containing a wave file
	Given an aip containing a wave file
	When populating the aip
	Then I should see E00000000_000000 intentitiy record
	And all E00000000_000000 representations should exist
	And I should have a datafile named files/obj1.wav
	And the datafile should be associated an audio stream