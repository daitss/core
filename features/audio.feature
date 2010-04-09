Feature: populate an aip containing an audio file 
Scenario: an aip containing a wave file
	Given an aip containing a wave file
	When populating the aip
	Then I should see info:fcla/7f9a69e00906012d6f780050569622ff intentitiy record
	And all info:fcla/7f9a69e00906012d6f780050569622ff representations should exist
	And I should have a datafile named obj1.wav
	And the datafile should be associated an audio stream