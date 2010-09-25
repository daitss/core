require 'spec_helper'
require 'daitss/proc/wip/process'
require 'uuid'

describe Wip do

  subject { submit 'haskell-nums-pdf' }

  it "should monitor the processing state" do
    subject.should_not be_running
    subject.start
    subject.should be_running
    subject.kill
    subject.should_not be_running
  end

end
