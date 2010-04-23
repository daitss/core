require 'spec_helper'
require 'datafile/describe'
require 'wip/xmlresolve'

describe Wip do

  before :all do
    @wip = submit 'mimi'
    @wip.original_datafiles.each { |df| df.describe! }
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

  it "should have an xml resolution event" do
    @wip.should have_key('xml-resolution-event')
  end

  it "should have an xml resolution agent" do
    @wip.should have_key('xml-resolution-agent')
  end

end
