require 'daitss/config'
require 'workspace'
require 'helper.rb'
require 'wip/trim_undescribed'

require 'daitss2'

REPO_ROOT = File.join File.dirname(__FILE__), ".."

NORMAL_WIP = File.join(REPO_ROOT, "spec", "wips", "normal_wip.zip")
TWO_UNDESCRIBED_FILES = File.join(REPO_ROOT, "spec", "wips", "two_undescribed.zip")

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

  it "should not delete any files when all are described" do
    wip_path = extract_wip_to_workspace NORMAL_WIP
    wip = Wip.new wip_path

    wip.trim_undescribed_datafiles
    puts `find #{wip.path}`
  end

  it "should delete any files that are undescribed in sip descriptor" do
    wip_path = extract_wip_to_workspace TWO_UNDESCRIBED_FILES

    wip = Wip.new wip_path

    wip.trim_undescribed_datafiles.should == 2
    puts `find #{wip.path}`
  end

end
