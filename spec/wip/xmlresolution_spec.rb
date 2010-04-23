require 'spec_helper'
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
  end

  it "should have an xml resolution agent for datafiles" do
    @df.should have_key('xml-resolution-agent')
  end

end
