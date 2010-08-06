require 'spec_helper'
require 'wip/state'

describe Wip do

  it 'should have dead wips be snafu' do

    id = UUID.generate :compact
    uri = "bogus:/#{id}"
    wip = blank_wip id, uri

    wip.should_not be_running
    wip.task = :sleep
    wip.start
    wip.should be_running

    wip.instance_eval do
      pid, ptime = process

      begin
        loop { Process.kill "KILL", pid.to_i }
      rescue Errno::ESRCH => e
        # nothing to do, best way to detect no proc
      end

    end

    wip.state.should == 'snafu'
  end

end
