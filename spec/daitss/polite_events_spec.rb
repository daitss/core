require 'daitss/model/event'

describe Event do

  it 'should have a polite name' do
    e = Event.new :name => 'ingest snafu'
    e.name.should match(/snafu/)
    e.polite_name.should_not match(/snafu/)
    e.polite_name.should match(/error/)
  end

end
