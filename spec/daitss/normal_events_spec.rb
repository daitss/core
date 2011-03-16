require 'daitss/model/package'

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
    the_names = Package::ABNORMAL_EVENTS + normal_event_names
    t = Time.now
    p.events = the_names.map { |name| Event.new :name => name, :agent => Agent.first, :timestamp => t += 1 }
    p.project = Project.first
    p.save or raise 'cannot save pacakge'
    p
  end

  it 'should not include abnormal events' do
    package.events.map(&:name) == normal_event_names
  end

  it 'should be in chronological order' do
    timestamps = package.events.map(&:timestamp)
    timestamps.should == timestamps.sort
  end

end
