require 'spec_helper'
require 'wip/process'
require 'uuid'

describe Wip do

  subject do
    id = UUID.generate :compact
    uri = "bogus:/#{id}"
    blank_wip id, uri
  end

  it "should monitor the processing state" do
    subject.should_not be_running
    subject.start { sleep }
    subject.should be_running
    subject.kill
    subject.should_not be_running
  end

end
