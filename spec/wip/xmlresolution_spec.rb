require 'spec_helper'
require 'wip/xmlresolve'

describe Wip do

  before :all do
    @wip = submit_sip 'mimi'
    @wip.xmlresolve
  end

  it "should have a xml resolution tarball" do
    @wip.should have_key('xml-resolution-tarball')
  end

  it "should have an xml resolution event" do
    @wip.should have_key('xml-resolution-event')
  end

  it "should have an xml resolution agent" do
    @wip.should have_key('xml-resolution-agent')
  end

end
