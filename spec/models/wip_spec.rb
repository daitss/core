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

end
