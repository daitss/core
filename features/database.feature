Feature: database population on various aip packages

Scenario: an aip containing a wave file
	Given an aip containing a wave file
	When populating the aip
	Then I should see info:fcla/7f9a69e00906012d6f780050569622ff intentitiy record
	And all info:fcla/7f9a69e00906012d6f780050569622ff representations should exist
	And I should have a datafile named obj1.wav
	And the datafile should be associated an audio stream


Scenario: an aip containing a pdf with many images
	Given an aip containing a pdf with many bitstream
	When populating the aip
	Then I should have a datafile named etd.pdf
 	And I should have 19 image bitstreams

Scenario: an aip containing a pdf with embedded fonts
	Given an aip containing a pdf with embedded fonts
	When populating the aip
	Then I should see test:/E0000194F_T3JNPR intentitiy record
	And all test:/E0000194F_T3JNPR representations should exist
	And I should have a datafile named Haskell98numbers.pdf
	And I should have a document with embedded fonts

Scenario: latest aip
	Given a latest aip
	When populating the aip
	And I should have a datafile named mimi.pdf
	
Scenario: an aip containing a jpeg file
	Given an aip containing a jpeg file
	When populating the aip
	Then I should see test:/E0000194F_Z9BEUK intentitiy record
	And all test:/E0000194F_Z9BEUK representations should exist
	And I should have a datafile named DSC04975_small.jpg
	And the datafile should be associated an image stream

Scenario: an aip containing a jp2 file
	Given an aip containing a jp2 file
	When populating the aip
	Then I should see test:/E0000194F_SQT19J intentitiy record
	And all test:/E0000194F_SQT19J representations should exist
	And I should have a datafile named WF00010502.jp2
	And there should be an image for bitstream in the datafile

Scenario: an aip containing a geotiff file
	Given an aip containing a geotiff file
	When populating the aip
	Then I should see test:/E0000194F_S2DMV5 intentitiy record
	And all test:/E0000194F_S2DMV5 representations should exist
 	And I should have a datafile named tjpeg.tif
 	And there should be an image for bitstream in the datafile	


Scenario: an aip with a normalized wave file 
	Given an aip with a normalized wave file 
	When populating the aip
	Then I should have a datafile named obj1.wav
	And the datafile should be associated with a normalization event
	And there should be a normalization relationship links to normalized file
	And the normalized file should be associated with an audio stream
	And the normalized file should have archive as origin
	And the original file should have depositor as origin
	
Scenario: an aip containing a xml
	Given an aip containing a xml
	When populating the aip
	Then I should see test:/E0000194F_T3JNPR intentitiy record
	And all test:/E0000194F_T3JNPR representations should exist
	And I should have a datafile named haskell-nums-pdf.xml
	And the datafile should be associated a text stream
	
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

Scenario: an aip containing a xml with an obsolete file
	Given an aip containing a xml with an obsolete file
	When populating the aip
	Then I should have not a datafile named 0-norm-0.wav

