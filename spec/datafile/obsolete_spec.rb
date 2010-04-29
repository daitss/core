require 'datafile/obsolete'
require 'spec_helper'

describe DataFile do

  subject do
    wip = submit 'mimi'
    wip.original_datafiles.first
  end

  it 'should know if it is obsolete' do
    subject.should_not be_obsolete
    subject.obsolete!
    subject.should be_obsolete
  end

  it 'should have an obsolete premis event' do
    subject.obsolete!
    subject.should have_key('obsolete-event')
  end

  it 'should have an obsolete premis event' do
    subject.obsolete!
    subject.should have_key('obsolete-agent')
  end

  it 'should raise an error for obsoleting an obsolete file' do
    subject.obsolete!
    lambda { subject.obsolete! }.should raise_error("#{subject} is already obsolete")
  end

end
