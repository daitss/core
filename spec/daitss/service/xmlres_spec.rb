require 'spec_helper'
require 'daitss/service/xmlres'

include Daitss

describe XmlRes do
  let(:package_id) { EggHeadKey.new_egg_head_key }
  let(:file) { File.join SIPS_DIR, *%w(ateam ateam.xml) }
  let(:uri) { 'a-fake-uri' }

  it 'should resolve a file' do
    xmlres = XmlRes.new
    xmlres.put_collection package_id
    event, agent = xmlres.resolve_file file, uri

    doc = Nokogiri::XML event
    doc.at('//P:linkingObjectIdentifierValue', NS_PREFIX).content.should == uri
    doc.at('//P:eventIdentifierValue', NS_PREFIX).content.should == uri + '/event/xmlresolution'

    doc = Nokogiri::XML agent
    doc.root.name.should == 'agent'
    doc.root.namespace.href.should == NS_PREFIX['P']

    tarball = File.join(Dir.tmpdir, package_id)
    xmlres.save_tarball tarball
    File.exist?(tarball).should be_true
    File.size(tarball).should > 0
    %x(tar tf #{tarball}).split("\n").size.should == 75
    File.delete tarball
  end

end
