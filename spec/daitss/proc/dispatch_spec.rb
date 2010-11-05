require 'daitss/model/request'
require 'daitss/proc/wip'
require 'fileutils'
require 'time'

include Daitss 

describe Request do

  URI_PREFIX = "test:/"

  before(:each) do
    archive
    sip = Sip.new :name => "mock_sip"
    @package = Package.new :sip => sip, :project => Project.first
    @agent = Agent.first
  end

  after(:each) do
    FileUtils.rm_rf(File.join(archive.workspace.path, @package.id))
  end

  it "should create a dissemination sub-wip" do
    request = Request.new :package => @package, :agent => @agent, :type => :disseminate 
    request.dispatch

    wip_path = File.join archive.workspace.path, request.package.id
    File.directory?(wip_path).should == true

    wip = Wip.new wip_path
    wip.tags["dissemination-request"].should_not be_nil
    wip.tags["drop-path"].should_not be_nil
    request.status.should == :released_to_workspace
  end

  it "should create a withdrawl sub-wip" do
    request = Request.new :package => @package, :agent => @agent, :type => :withdraw
    request.dispatch

    wip_path = File.join archive.workspace.path, request.package.id
    File.directory?(wip_path).should == true

    wip = Wip.new wip_path
    wip.tags["withdrawal-request"].should_not be_nil
    request.status.should == :released_to_workspace
  end

  it "should create a peek sub-wip" do
    request = Request.new :package => @package, :agent => @agent, :type => :peek
    request.dispatch

    wip_path = File.join archive.workspace.path, request.package.id
    File.directory?(wip_path).should == true

    wip = Wip.new wip_path
    wip.tags["peek-request"].should_not be_nil
    request.status.should == :released_to_workspace
  end

  it "should create a migration sub-wip" do
    request = Request.new :package => @package, :agent => @agent, :type => :migration
    request.dispatch

    wip_path = File.join archive.workspace.path, request.package.id
    File.directory?(wip_path).should == true

    wip = Wip.new wip_path
    wip.tags["migration-request"].should_not be_nil
    request.status.should == :released_to_workspace
  end
end
