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
  end

  it "should have an xml resolution event" do
    @wip.should have_key('xml-resolution-event')
  end

  it "should have an xml resolution agent" do
    @wip.should have_key('xml-resolution-agent')
  end

  it "should cleanup the tarball" do
    pending "deletion is not implemented in xmlresolution service"
    url = URI.parse "#{Daitss::CONFIG['xmlresolution-url']}/ieids/#{@wip.id}/"
    req = Net::HTTP::Head.new url.path
    res = Net::HTTP.start(url.host, url.port) { |http| http.request req }
    res.should be_a_kind_of(Net::HTTPNotFound)
  end

end
