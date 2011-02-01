require 'daitss/proc/wip/tarball'
require 'daitss/proc/wip/preserve'

shared_examples_for "all preservations" do

  it "should have every datafile described" do
    pending "test needs to be updated, preservation is currently being counted as a single step"

    @wip.all_datafiles.each do |df|
      @wip.journal.should have_key("describe-#{df.id}")
      df.should have_key('describe-file-object')
      df.should have_key('describe-event')
      df.should have_key('describe-agent')
    end

  end

  it 'should have the xmlresolution tarball' do
    File.exist?(@wip.xmlres_file).should be_true
    File.size(@wip.xmlres_file).should > 0
  end

end

describe Wip do

  describe "with no normalization" do
    it_should_behave_like "all preservations"

    before :all do
      @wip = submit 'lorem'
      @wip.preserve

      @files = {
        :xml => @wip.original_datafiles.find { |df| df['sip-path'] == 'lorem.xml' },
        :txt => @wip.original_datafiles.find { |df| df['sip-path'] == 'lorem_ipsum.txt' },
      }

    end

    it "should not have a normalized representation" do
      @wip.normalized_datafiles.should be_empty
    end

  end

  describe "with one normalization" do
    it_should_behave_like "all preservations"

    before :all do
      @wip = submit 'wave'
      @wip.preserve
    end

    it "should have an original representation with only an xml and a pdf" do
      o_rep = @wip.original_representation
      o_rep.should have_exactly(2).items
      aip_paths = o_rep.map { |f| f['aip-path'] }
      aip_paths.should include(File.join(Wip::SIP_FILES_DIR, 'obj1.wav'))
      aip_paths.should include(File.join(Wip::SIP_FILES_DIR, 'wave.xml'))
    end

    it "should have a current representation just with only an xml and a wav" do
      c_rep = @wip.current_representation
      c_rep.should have_exactly(2).items
      aip_paths = c_rep.map { |f| f['aip-path'] }
      aip_paths.should include(File.join(Wip::SIP_FILES_DIR, 'obj1.wav'))
      aip_paths.should include(File.join(Wip::SIP_FILES_DIR, 'wave.xml'))
    end

    it "should have a normalized representation just with only an xml and a wavn" do
      n_rep = @wip.normalized_representation
      n_rep.should have_exactly(2).items
      aip_paths = n_rep.map { |f| f['aip-path'] }
      aip_paths.should include(File.join(Wip::AIP_FILES_DIR, '1-norm-0.wav'))
      aip_paths.should include(File.join(Wip::SIP_FILES_DIR, 'wave.xml'))
    end

  end

end
