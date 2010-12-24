require 'spec_helper'
require 'daitss/service/virus'

include Daitss

describe Virus do
  let(:clean) { File.join SIPS_DIR, *%w(ateam-virus ateam.tiff) }
  let(:infected) { File.join SIPS_DIR, *%w(ateam-virus eicar.com) }
  let(:uri) { 'a-fake-uri' }

  it 'should post to the service' do
    v = Virus.new clean, uri
    lambda { v.post }.should_not raise_error
  end

  it 'should return an event' do
    v = Virus.new clean, uri
    v.post
    doc = Nokogiri::XML v.event
    doc.at('//P:linkingObjectIdentifierValue', NS_PREFIX).content.should == uri
    doc.at('//P:eventIdentifierValue', NS_PREFIX).content.should == uri + '/event/virus-check'
  end

  it 'should return an agent' do
    v = Virus.new clean, uri
    v.post
    doc = Nokogiri::XML v.agent
    doc.root.name.should == 'agent'
    doc.root.namespace.href.should == NS_PREFIX['P']
  end

end
