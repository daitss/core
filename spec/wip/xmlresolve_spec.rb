require 'spec_helper'
require 'nokogiri'
require 'datafile/describe'
require 'wip/xmlresolve'

describe Wip do

  before :all do
    @wip = submit 'mimi'
    @wip.original_datafiles.each { |df| df.describe! }
    @df = @wip.original_datafiles.find { |df| df['aip-path'] =~ /\.xml$/}
    @wip.xmlresolve!
  end

  it "should have a xml resolution tarball" do
    @wip.should have_key('xml-resolution-tarball')

    Tempfile.open 'spec' do |t|
      t.write @wip['xml-resolution-tarball']
      t.flush
      tarlist = %x{tar tf #{t.path}}.lines
      tarlist.should have_exactly(72).items
    end

  end

  it "should have an xml resolution event for datafiles" do
    @df.should have_key('xml-resolution-event')
    doc = XML::Document.string @df['xml-resolution-event']
    doc.find("/P:event", NS_PREFIX).should_not be_empty
    doc.find("/P:event//P:linkingObjectIdentifierValue = '#{@df.uri}'", NS_PREFIX).should be_true
  end

  it "should have an xml resolution agent for datafiles" do
    @df.should have_key('xml-resolution-agent')
    doc = XML::Document.string @df['xml-resolution-agent']
    doc.find("/P:agent", NS_PREFIX).should_not be_empty
  end

end
