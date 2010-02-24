Feature: populate an aip containing an image file 
Scenario: an aip containing a jpeg file
	Given an aip containing a jpeg file
	When populating the aip
	Then I should see E00000000_000000 intentitiy record
	And all E00000000_000000 representations should exist
	And I should have a datafile named DSC04975_small.jpg
	And the datafile should be associated an image stream
	
Scenario: an aip containing a jp2 file
	Given an aip containing a jp2 file
	When populating the aip
	Then I should see E00000000_000000 intentitiy record
	And all E00000000_000000 representations should exist
	And I should have a datafile named WF00010502.jp2
	And there should be an image for bitstream in the datafile
	
Scenario: an aip containing a geotiff file
	Given an aip containing a geotiff file
	When populating the aip
	Then I should see E00000000_000000 intentitiy record
	And all E00000000_000000 representations should exist
	And I should have a datafile named tjpeg.tif
	And there should be an image for bitstream in the datafile	