describe 'profiling wips' do

  let(:wip) do
    wip = submit 'haskell-nums-pdf'
    wip.spawn
    sleep 0.3 while wip.running?
    wip.should_not be_snafu
    wip.package.aip.should_not be_nil
    sleep 1
    wip
  end

  let(:files) do
    id = wip.id

    Dir.chdir archive.profile_path do
      Dir["#{id}.ingest.*"]
    end

  end

  it 'should create a profile for a wip' do
    pending "profiling disabled, for now"
    f = files.find { |f| f =~ /\.prof.html$/ }
    f.should_not be_nil
  end

  it 'should create a profile for a wip' do
    f = files.find { |f| f =~ /\.journal$/ }
    f.should_not be_nil
  end

end
