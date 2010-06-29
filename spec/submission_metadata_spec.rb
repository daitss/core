require 'daitss/config'
require 'workspace'
require 'helper.rb'
require 'wip/submission_metadata'

require 'daitss2'

REPO_ROOT = File.join File.dirname(__FILE__), ".."

NORMAL_WIP = File.join(REPO_ROOT, "spec", "wips", "normal_wip.zip")

describe Wip do

  before(:each) do
    Daitss::CONFIG.load_from_env

    @workspace = Workspace.new Daitss::CONFIG['workspace']
  end

  after(:each) do
    FileUtils.rm_rf File.join(@workspace.path, "E0000199Y_L35FP3")
  end

  # extracts wip to workspace, returns path to wip
  def extract_wip_to_workspace wip_path
    zip_command = `which unzip`.chomp
    raise "unzip utility not found on this system!" if zip_command =~ /not found/

    output = `#{zip_command} -o #{wip_path} -d #{@workspace.path} 2>&1`
    raise "zip returned non-zero exit status: #{output}" unless $?.exitstatus == 0

    # all test wips share this IEID
    return File.join @workspace.path, "E0000199Y_L35FP3"
  end

  #TODO: xpaths for a more thourough test
  it "should create an agent for submission service" do
    wip_path = extract_wip_to_workspace NORMAL_WIP
    wip = Wip.new wip_path

    wip.create_submit_agent

    wip["submit-agent"].should_not be_nil
  end

  #TODO: xpaths for a more thourough test
  it "should create an agent for the account" do
    wip_path = extract_wip_to_workspace NORMAL_WIP
    wip = Wip.new wip_path

    wip.create_account_agent

    wip["submit-agent-account"].should_not be_nil
  end

  #TODO: xpaths for a more thourough test
  it "should create an event for submission" do
    wip_path = extract_wip_to_workspace NORMAL_WIP
    wip = Wip.new wip_path

    wip.create_submit_event

    wip["submit-event"].should_not be_nil
  end

  #TODO: xpaths for a more thourough test
  it "should create an event for acceptance" do
    wip_path = extract_wip_to_workspace NORMAL_WIP
    wip = Wip.new wip_path

    wip.create_accept_event

    wip["accept-event"].should_not be_nil
  end

  #TODO: xpaths for a more thourough test
  it "should create an event for package validation" do
    wip_path = extract_wip_to_workspace NORMAL_WIP
    wip = Wip.new wip_path

    wip.create_package_valid_event

    wip["package-valid-event"].should_not be_nil
  end

  #TODO: xpaths for a more thourough test
  it "should create an event for deleted datafile event" do
    wip_path = extract_wip_to_workspace NORMAL_WIP
    wip = Wip.new wip_path

    datafile = wip.original_datafiles.first

    wip.add_deleted_datafile_event datafile

    wip["deleted-undescribed-file-#{datafile.id}"].should_not be_nil
  end
end
