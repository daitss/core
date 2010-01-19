require 'xml'
require 'aip'

abs = FileUtils.pwd
aip = AIP.new

Given /^an aip containing a pdf with embedded fonts$/ do
  @file = "#{abs}/files/pdf-monodescriptor.xml"
end

Given /^an aip containing a pdf with many bitstream$/ do
  @file = "#{abs}/files/multi-bs-pdf.xml"
end

Given /^an aip containing a wave file$/ do
  @file = "#{abs}/files/audio_wave.xml"
end

Given /^an aip with a normalized wave file$/ do
   @file = "#{abs}/files/audio_wave.xml"
end

Given /^an aip containing a jpeg file$/ do
  @file = "#{abs}/files/jpeg.xml"
end

Given /^an aip containing a jp2 file$/ do
  @file = "#{abs}/files/jp2.xml"
end

Given /^an aip containing a xml$/ do
  @file = "#{abs}/files/pdf-monodescriptor.xml"
end

When /^populating the aip$/ do
  aip.process @file
end

Then /^I should see (.+?) intentitiy record$/ do |ieid|
  intentity = Intentity.get(ieid)
  intentity.should_not be_nil
end

Then /^all (.+) representations should exist/ do |ieid|
  # check for representation-0, representation-current
  r0 = Representation.first(:intentity_id => ieid, :id => 'representation-0')
  r0.should_not be_nil
  rc = Representation.first(:intentity_id => ieid, :id => 'representation-current')
  rc.should_not be_nil
end
	
Then /^I should have a datafile named (.+)/ do |filename|
  puts filename
  df = Datafile.first(:original_path => filename)
  df.should_not be_nil
  @dfid = df.id
end

Then /^I should have a document with embedded fonts$/ do
  document = Document.first(:datafile_id => @dfid)
  document.should_not be_nil
  fonts = Font.all(:document_id => document.id)
  fonts.each {|font| font.embedded.should == true}
end

Then /^I should have (.+) image bitstreams$/ do |numOfBitstreams|
  count = Bitstream.count(:datafile_id => @dfid)
  count.should == numOfBitstreams.to_i
end

Then /^the datafile should be associated an audio stream$/ do
  audio = Audio.first(:datafile_id => @dfid)
  audio.should_not be_nil
end


Then /^the datafile should be associated an image stream$/ do
  image = Image.first(:datafile_id => @dfid)
  image.should_not be_nil
end

Then /^there should be an image for bitstream in the datafile$/ do
  bitstream = Bitstream.first(:datafile_id => @dfid)
  image = Image.first(:bitstream_id => bitstream.id)
  image.should_not be_nil
end

Then /^the datafile should be associated a text stream$/ do
  text = Text.first(:datafile_id => @dfid)
  text.should_not be_nil
end

When /^the datafile should be associated with a normalization event$/ do
  event = Event.first(:relatedObjectId => @dfid, :e_type =>:normalize)
  event.should_not be_nil
end

When /^there should be a normalization relationship links to normalized file$/ do
  relationship = Relationship.first(:object1 => @dfid, :type => :normalized_to)
  relationship.should_not be_nil
  @norm_fileid = relationship.object2
end

When /^the normalized file should be associated an audio stream$/ do
  audio = Audio.first(:datafile_id => @norm_fileid)
  audio.should_not be_nil
end
