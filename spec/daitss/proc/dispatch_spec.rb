require 'spec_helper'

require 'daitss/model/request'
require 'daitss/proc/wip'

require 'fileutils'
require 'time'

describe Request do

  let :package do
    sip = Sip.new :name => "mock_sip"
    Package.new :sip => sip, :project => Project.first
  end

  let(:agent) { Agent.first }

  after(:each) { FileUtils.rm_r package.wip.path }

  Wip::VALID_TASKS.each do |t|

    it "should create a wip for #{t}" do
      request = Request.new :package => package, :agent => agent, :type => t
      request.dispatch
      package.wip.should_not be_nil
      package.wip.path.should exist_on_fs
      package.wip.task.should == t
      request.status.should == :released_to_workspace
    end

  end

end
