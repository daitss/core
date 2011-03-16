require 'daitss/model/package'

describe Package do

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
    the_names = Package::LEGACY_EVENTS + Package::FIXITY_PASSED_EVENTS + Package::FIXITY_FAILED_EVENTS + normal_event_names
    t = Time.now
    p.events = the_names.map { |name| Event.new :name => name, :agent => Agent.first, :timestamp => t += 1 }
    p.project = Project.first
    p.save or raise 'cannot save pacakge'
    p
  end


  describe '#normal_events' do

    it 'should not include fixity or legacy events' do
      package.events.map(&:name) == normal_event_names
    end

    it 'should be in chronological order' do
      timestamps = package.events.map(&:timestamp)
      timestamps.should == timestamps.sort
    end

  end

  describe 'legacy_events' do

    it 'should not include normal events' do
      package.legacy_events.each do |e|
        normal_event_names.should_not include(e.name)
      end
    end

    it 'should not include fixity events' do
      package.legacy_events.each do |e|
        (Package::FIXITY_PASSED_EVENTS + Package::FIXITY_FAILED_EVENTS).should_not include(e.name)
      end
    end

    it 'should be in chronological order' do
      timestamps = package.events.map(&:timestamp)
      timestamps.should == timestamps.sort
    end

  end

  describe 'fixity_events' do

    it 'should not include normal events' do
      package.fixity_events.each do |e|
        normal_event_names.should_not include(e.name)
      end
    end

    it 'should not include fixity events' do
      package.fixity_events.each do |e|
        Package::LEGACY_EVENTS.should_not include(e.name)
      end
    end

    it 'should be in chronological order' do
      timestamps = package.events.map(&:timestamp)
      timestamps.should == timestamps.sort
    end

  end

end
