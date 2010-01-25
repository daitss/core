require 'spec_helper'
require 'xmlns'
require 'service/actionplan'

describe 'action planning a datafile' do

  subject do
    wip = submit_sip 'mimi'
    wip.datafiles.find { |df| df['sip-path'] =~ %r{\.pdf$} }
  end

  it "should return nil if there is no migration" do
    subject.migration.should be_nil
  end

end
