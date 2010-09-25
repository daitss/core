require 'spec_helper'
require 'daitss/proc/wip/state'

describe Wip do

  subject { submit 'haskell-nums-pdf' }

  it 'should have dead subject. be snafu' do

    subject.should_not be_running
    subject.task = :sleep
    subject.start
    subject.should be_running

    subject.instance_eval do
      pid, ptime = process

      begin
        loop { Process.kill "KILL", pid.to_i }
      rescue Errno::ESRCH => e
        # nothing to do, best way to detect no proc
      end

    end

    subject.state.should == 'snafu'
  end

end
