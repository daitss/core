require 'xml'
require 'AIPInPremis'

abs = File.join File.dirname(__FILE__), '..'

Given /^an aip containing a pdf with embedded fonts$/ do
  @file = "#{abs}/files/pdf-monodescriptor.xml"
end

Given /^an aip containing a pdf with many bitstream$/ do
  @file = "#{abs}/files/multi-bs-pdf.xml"
end

Given /^an aip containing a pdf with inhibitor$/ do
  @file = "#{abs}/files/pw-pdf.xml"
end

Given /^an aip containing a pdf with anomaly$/ do
  @file = "#{abs}/files/pw-pdf.xml"
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

Given /^an aip containing a geotiff file$/ do
  @file = "#{abs}/files/geotiff.xml"
end

Given /^an aip containing a xml$/ do
  @file = "#{abs}/files/pdf-monodescriptor.xml"
end

Given /^a latest aip$/ do
    @file = "#{abs}/files/02pdf.xml"
end

Given /^an aip containing a xml with broken links$/ do
  @file = "#{abs}/files/brokenLinks.xml"
end

Given /^an aip containing a xml with an obsolete file$/ do
  @file = "#{abs}/files/obsoleteFiles.xml"
end

When /^populating the aip$/ do
  aip = AIPInPremis.new
  aip.processAIPFile @file
end

Then /^I should see (.+?) intentitiy record$/ do |ieid|
  intentity = Intentity.get(ieid)
  intentity.should_not be_nil
end

Then /^all (.+) representations should exist/ do |ieid|
  # check for representation-0, representation-current
  r0 = Datafile.first(:intentity_id => ieid, :r0.like  => '%representation/original')
  r0.should_not be_nil
  rc = Datafile.first(:intentity_id => ieid, :rc.like  => '%representation/current')
  rc.should_not be_nil
end

Then /^I should have a datafile named (.+)/ do |filename|
  df = Datafile.first(:original_path => filename)
  df.should_not be_nil
  @dfid = df.id
end

Then /^I should have not a datafile named (.+)/ do |filename|
  df = Datafile.first(:original_path => filename)
  df.should be_nil
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

Then /^the datafile should be associated with a normalization event$/ do
  event = Event.first(:relatedObjectId => @dfid, :e_type =>:normalize)
  event.should_not be_nil
end

Then /^there should be a normalization relationship links to normalized file$/ do
  relationship = Relationship.first(:object1 => @dfid, :type => :normalized_to)
  relationship.should_not be_nil
  @norm_fileid = relationship.object2
end

Then /^the normalized file should be associated with an audio stream$/ do
  audio = Audio.first(:datafile_id => @norm_fileid)
  audio.should_not be_nil
end

Then /^the normalized file should have archive as origin$/ do
 df = Datafile.first(:id => @norm_fileid)
 df.origin.should == :archive
end

Then /^the original file should have depositor as origin$/ do
  df = Datafile.first(:id => @dfid)
  df.origin.should == :depositor
end

Then /^it should have an inhibitor$/ do
  df = Datafile.first(:id => @dfid)
  found = false
  df.datafile_severe_element.each do |dfse|
    se = SevereElement.first(:id => dfse.severe_element_id)
    found = true if se.class == Inhibitor
  end
  found.should == true
end


Then /^it should have an anomaly$/ do
  df = Datafile.first(:id => @dfid)
  found = false
  df.datafile_severe_element.each do |dfse|
    se = SevereElement.first(:id => dfse.severe_element_id)
    found = true if se.class == Anomaly
  end
  found.should == true
end

Then /^it should have a broken link$/ do
  brokenLink = BrokenLink.first(:datafile_id => @dfid)
  brokenLink.should_not be_nil
end