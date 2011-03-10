describe DataFile do

  subject do
    wip = make_new_wip
    wip.new_original_datafile '0'
  end

  it "should let one add new metadata" do
    subject['sip-path'] = 'foo/bar/baz'
    subject['sip-path'].should == 'foo/bar/baz'
  end

  it "should let one read and write the data" do
    subject.open("w") { |io| io.write "foo" }
    subject.open { |io| io.read }.should == "foo"
  end

  it "should have a uri" do
    subject.uri.should == "#{subject.wip.package.uri}/file/#{subject.id}"
  end

  it "should equal datafiles with the same path" do
      df_1 = subject.wip.original_datafiles.first
      df_2 = subject.wip.original_datafiles.first

      df_1.should == df_2
  end

  it "should know its size" do
      subject.open('w') { |io| io.write '123' }
      subject.size.should == 3
  end

  it "should give access to the underlying fs file" do
    subject.data_file.should exist_on_fs
  end

end
