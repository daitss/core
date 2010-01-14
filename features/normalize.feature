Feature: populate an aip containing normalized file
Scenario: an aip with a normalized wave file 
	Given an aip with a normalized wave file 
	When populating the aip
	And I should have a datafile named files/obj1.wav
	And the datafile should be associated with a normalization event
	And there should be a normalization relationship links to normalized file
	And the normalized file should be associated an audio stream