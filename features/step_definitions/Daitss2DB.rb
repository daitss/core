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

Then /^I should have many image bitstreams$/ do
  bitstreams = Bitstream.count(:datafile_id => @dfid)
  puts bitstreams
end

Then /^I should have an audio stream$/ do
  pending # express the regexp above with the code you wish you had
end
