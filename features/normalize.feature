Feature: populate an aip containing normalized file
Scenario: an aip with a normalized wave file 
	Given an aip with a normalized wave file 
	When populating the aip
	Then I should have a datafile named obj1.wav
	And the datafile should be associated with a normalization event
	And there should be a normalization relationship links to normalized file
	And the normalized file should be associated with an audio stream
	And the normalized file should have archive as origin
	And the original file should have depositor as origin