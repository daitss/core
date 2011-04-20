describe Wip do
  let :wip do
    p = make_new_package
    path = File.join DataDir.work_path, p.id
    Wip.create path, :disseminate
  end

  let :other_wip do
    p = Package.new
    ac = Account.get OPERATIONS_ACCOUNT_ID
    p.project = ac.default_project
    p.sip = Sip.new :name => "foo"
    p.save or raise "cant save package"
    path = File.join DataDir.work_path, p.id
    Wip.create path, :disseminate
  end

  it "should let addition of new files" do
    df = wip.new_original_datafile 0
    df.open('w') { |io| io.write 'foo' }
    df.open { |io| io.read }.should == 'foo'
  end

  it "should not let the addition of existing datafiles" do
    wip.new_original_datafile 0
    lambda { wip.new_original_datafile 0 }.should raise_error(/datafile 0 already exists/)
  end

  it "should let addition of new metadata" do
    s = "submitted at #{Time.now}"
    wip['submit-event'] = s
    wip['submit-event'].should == s
  end

  it "should equal a wip with the same path" do
    other = Wip.new wip.path
    wip.should == other
  end

  it "should not equal a wip with a different path" do
    wip.should_not == other_wip
  end

  describe "create from request" do

    let(:req) do
      a = Account.make :id => 'ACT'
      proj = Project.make :id => 'PRJ', :account => a
      p = Package.make :project => proj
      p.sip = Sip.new :name => "foo"
      r = Request.new(:type => :ingest, :agent => Operator.first)
      p.requests << r
      p.save or raise "Can't save package or sip"
      f = 'haskell-nums-pdf.tar'
      s = Submission.extract sip_fixture_path(f), :filename => f, :package => p
      r
    end

    let(:wip) do
      Wip.create_from_request req
    end

    it 'should have the task' do
      wip.task.should == :ingest
    end

    it 'should have all the datafiles' do
      wip.original_datafiles.map { |df| df['sip-path'] }.should == req.submission.files
    end

    it 'should have the sip descriptor' do
      wip['sip-descriptor'].should_not be_nil
    end

    it 'should have the issue'
    it 'should have the volume'
    it 'should have the title'
    it 'should have the entity id'
  end

  describe "dmd access" do

    require 'libxml'

    let(:wip) do
      a = Account.make :id => 'ACT'
      proj = Project.make :id => 'PRJ', :account => a
      p = Package.make :project => proj
      p.sip = Sip.new :name => "foo"
      p.save or raise "Can't save package or sip"

      f = 'haskell-nums-pdf.tar'
      s = Submission.extract sip_fixture_path(f), :filename => f, :package => p

      w = Wip.create File.join(DataDir.work_path, p.id), :ingest

      s.files.each_with_index do |f, n|
        df = w.new_original_datafile n

        FileUtils.cp File.join(s.path, f), df.data_file
      end

      w['dmd-issue'] = s.issue
      w['dmd-title'] = s.title
      w['dmd-volume'] = s.volume
      w['dmd-entity-id'] = s.entity_id

      w
    end

    it "should know if dmd exists" do
      Wip::DMD_KEYS.each do |key|
        Wip::DMD_KEYS.each { |k| wip.delete k if wip.has_key? k }
        wip.should_not have_dmd
        wip[key] = "value for #{key}"
        wip.should have_dmd
      end
    end

    it "should make some xml for dmd if it exists" do
      wip['dmd-issue'] = CGI.escape "l'issue"
      wip['dmd-volume'] = 'le volume'
      wip['dmd-title'] = 'le titre'
      wip['dmd-entity-id'] = 'lentityid'
      doc = LibXML::XML::Document.string wip.dmd
      doc.find("/mods:mods/mods:titleInfo/mods:title = '#{ wip['dmd-title'] }'", NS_PREFIX).should be_true
      doc.find("/mods:mods/mods:part/mods:detail[@type = 'volume']/mods:number = '#{ wip['dmd-volume'] }'", NS_PREFIX).should be_true
      doc.find("/mods:mods/mods:part/mods:detail[@type = 'issue']/mods:number = '#{ wip['dmd-issue'] }'", NS_PREFIX).should be_true
      doc.find("/mods:mods/mods:identifier[@type = 'entity id'] = '#{ wip['dmd-entity-id'] }'", NS_PREFIX).should be_true
    end

  end

end
