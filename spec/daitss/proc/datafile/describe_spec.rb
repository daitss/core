require 'spec_helper'
require 'daitss/xmlns'
require 'daitss/proc/datafile/describe'

describe 'describing a datafile' do

  subject do
    @wip = submit 'mimi'
    @wip.original_datafiles.find { |df| df['aip-path'] == File.join(Aip::SIP_FILES_DIR, 'mimi.pdf') }
  end

  describe "premis metadata" do

    before(:all) { subject.describe! }
    it { should have_key('describe-event') }
    it { should have_key('describe-agent') }
    it { should have_key('describe-file-object') }
    it { should have_key('describe-bitstream-objects') }

    it "should have the datafile's uri as the of the premis file object" do
      doc = XML::Document.string subject['describe-file-object']
      file_object = doc.find_first "/P:object[@xsi:type = 'file']", NS_PREFIX
      file_object.should_not be_nil

      obj_id_type = file_object.find_first "P:objectIdentifier/P:objectIdentifierType", NS_PREFIX
      obj_id_type.should_not be_nil
      obj_id_type.content.should == 'URI'

      obj_id_value = file_object.find_first "P:objectIdentifier/P:objectIdentifierValue", NS_PREFIX
      obj_id_value.should_not be_nil
      obj_id_value.content.should == subject.uri
    end

    it "should have the datafile's uri as the base for any bitstreams" do
      doc = XML::Document.string subject['describe-bitstream-objects']
      bs_objects = doc.find "/P:object[@xsi:type = 'bitstream']", NS_PREFIX
      bs_objects.should_not be_empty

      bs_objects.each do |bs_object|
        obj_id_type = bs_object.find_first "P:objectIdentifier/P:objectIdentifierType", NS_PREFIX
        obj_id_type.should_not be_nil
        obj_id_type.content.should == 'URI'

        obj_id_value = bs_object.find_first "P:objectIdentifier/P:objectIdentifierValue", NS_PREFIX
        obj_id_value.should_not be_nil
        obj_id_value.content.should =~ %r(#{subject.uri}/\d+)
      end

    end

    it "should have the sip path inplace for the originalName" do
      doc = XML::Document.string subject['describe-file-object']
      file_object = doc.find_first "/P:object[@xsi:type = 'file']", NS_PREFIX
      file_object.should_not be_nil

      obj_id_type = file_object.find_first "P:originalName", NS_PREFIX
      obj_id_type.should_not be_nil
      obj_id_type.content.should == File.join(Aip::SIP_FILES_DIR, subject['sip-path'])
    end

    it 'should have a message digest originator of depositor' do
      doc = XML::Document.string subject['describe-file-object']
      file_object = doc.find_first "/P:object[@xsi:type = 'file']", NS_PREFIX
      file_object.should_not be_nil

      file_object.find(%Q{
        P:objectCharacteristics /
          P:fixity /
            P:messageDigestOriginator = 'Archive'
      }, NS_PREFIX).should be_true

      file_object.find(%Q{
        P:objectCharacteristics /
          P:fixity /
            P:messageDigestOriginator = 'Depositor'
      }, NS_PREFIX).should be_true
    end

    it 'should have a message digest originator of archive' do
      df = @wip.new_original_datafile 'foo'
      df.open('w') { |io| io.puts 'plain text' }
      df.describe!
      doc = XML::Document.string df['describe-file-object']
      file_object = doc.find_first "/P:object[@xsi:type = 'file']", NS_PREFIX
      file_object.should_not be_nil

      file_object.find(%Q{
        P:objectCharacteristics /
          P:fixity /
            P:messageDigestOriginator = 'Archive'
      }, NS_PREFIX).should be_true

      file_object.find(%Q{
        P:objectCharacteristics /
          P:fixity /
            P:messageDigestOriginator = 'Depositor'
      }, NS_PREFIX).should be_false
    end

  end

  describe 'transformation options' do

    before :all do
      @df = subject
      @df['transformation-source'] = 'autobot://optimus/prime'
      @df['transformation-strategy'] = 'migrate'
      @df['migrate-agent'] = 'foo bar'
      @df['migrate-event'] = XML::Document.string %Q{
        <event xmlns="info:lc/xmlns/premis-v2">
          <eventIdentifier>
            <eventIdentifierType>URI</eventIdentifierType>
            <eventIdentifierValue>foo</eventIdentifierValue>
          </eventIdentifier>
          <eventType>#{ @df['transformation-strategy'] }</eventType>
          <linkingAgentIdentifier>
            <linkingAgentIdentifierValue>#{@df['migrate-agent']}</linkingAgentIdentifierValue>
          </linkingAgentIdentifier>
          <linkingObjectIdentifier>
            <linkingObjectIdentifierValue>#{ @df['transformation-source'] }</linkingObjectIdentifierValue>
            <linkingObjectRole>source</linkingObjectRole>
          </linkingObjectIdentifier>
          <linkingObjectIdentifier>
            <linkingObjectIdentifierValue>#{ @df.uri }</linkingObjectIdentifierValue>
            <linkingObjectRole>outcome</linkingObjectRole>
          </linkingObjectIdentifier>
        </event>
      }
      @df['transformation-agent'] = 'cybertron'
      @df.describe!
    end

    it 'should relate to the source via an event' do

      # the related obejct
      object_doc = XML::Document.string @df['describe-file-object']
      relationship = object_doc.find_first(%Q{
        P:relationship[
          P:relatedObjectIdentification/
            P:relatedObjectIdentifierValue = '#{ @df['transformation-source'] }']
      } , NS_PREFIX)
      relationship.should_not be_nil

      # the event
      rel_event = relationship.find_first(%Q{
        P:relatedEventIdentification /
          P:relatedEventIdentifierValue
      }, NS_PREFIX)
      rel_event.should_not be_nil
      event_doc = XML::Document.string @df["#{ @df['transformation-strategy'] }-event"]
      event = event_doc.find_first(%Q{
        /P:event [
          P:eventIdentifier /
            P:eventIdentifierValue = '#{rel_event.content}'
        ]
      }, NS_PREFIX)
      event.should_not be_nil
      event.find("P:eventType = '#{ @df['transformation-strategy'] }'", NS_PREFIX).should be_true

      event.find(%Q{
        P:linkingObjectIdentifier [P:linkingObjectRole = 'source'] /
          P:linkingObjectIdentifierValue = '#{ @df['transformation-source'] }'
      }, NS_PREFIX).should be_true

      event.find(%Q{
        P:linkingObjectIdentifier [P:linkingObjectRole = 'outcome'] /
          P:linkingObjectIdentifierValue = '#{ @df.uri }'
      }, NS_PREFIX).should be_true

      # the agent
      event.find(%Q{
        P:linkingAgentIdentifier /
          P:linkingAgentIdentifierValue = '#{ @df['migrate-agent'] }'
      }, NS_PREFIX).should be_true
    end

  end

end

describe 'a datafile with multiple bitstreams' do

  it "should have multiple bitstreams" do
    wip = submit 'etd'
    df = wip.original_datafiles.find { |df| df['aip-path'] == File.join(Aip::SIP_FILES_DIR, 'etd.pdf') }
    df.describe!
    df.bitstream_objects.size.should == 19
  end

end
