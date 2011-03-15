describe Package, '#normal_events' do

  let :normal_event_names do
    [
      'ingest started',
      'ingest snafu',
      'ingest started',
      'ingest stopped',
      'ingest finished'
    ]
  end

  let :package do
    p = Package.new
    the_names = ABNORMAL_EVENTS + normal_event_names
    p.events = the_names.map { |name| Event.new :name => name }
    p.save or raise 'cannot save pacakge'
    p
  end

  it 'should not include abnormal events' do
    p.events.map(&:name) == normal_event_names
  end

  it 'should be in chronological order' do
    timestamps = p.events.map(&:timestamp)
    timestamps.should == timestamps.sort
  end

end
