require 'db/operations_agents'
require 'db/operations_events'
require 'db/aip'
require 'daitss/config'
require 'fileutils'

REPO_ROOT = File.join File.dirname(__FILE__), '..', '..'
VAR_DIR = File.join REPO_ROOT, 'var'
SIP_DIR = File.join REPO_ROOT, 'spec', 'sips'
SERVICES_DIR = File.join VAR_DIR, 'services'

SUBMISSION_CLIENT_PATH = File.join SERVICES_DIR, "submission", "submit-filesystem.rb"
INGEST_BIN_PATH = File.join REPO_ROOT, "bin", "ingest"

# setup config
raise "CONFIG not set" unless ENV['CONFIG']
Daitss::CONFIG.load ENV['CONFIG']
DataMapper.setup :default, Daitss::CONFIG['database-url']

def submit_via_client package
  raise "No users created" unless @username and @password

  sip_path = File.join SIP_DIR, package
  raise "Specified SIP not found" unless File.directory? sip_path

  output = `#{SUBMISSION_CLIENT_PATH} --url #{Daitss::CONFIG['submission-url']} --package #{sip_path} --name #{package} --username #{@username} --password #{@password}`
  raise "Submission seems to have failed: #{output}" unless $?.exitstatus == 0

  return output.chomp
end

def run_ingest ieid, expect_success = true
  raise "No IEID to ingest" unless ieid

  output = `#{INGEST_BIN_PATH} #{ieid}`
  raise "Ingest seems to have failed: #{output}" if ($?.exitstatus != 0 and expect_success == true)
end

def setup_workspace
  raise "$WORKSPACE not set" unless ENV["WORKSPACE"]

  FileUtils.rm_rf(ENV["WORKSPACE"]) if File.directory? ENV["WORKSPACE"]
  FileUtils.mkdir_p ENV["WORKSPACE"]
end

Given /^an archive (\w+)$/ do |actor|

  case actor

  when "operator"
    a = add_account
    add_project a
    add_operator a

    @username = "operator"
    @password = "operator"

  when "contact"
    a = add_account "ACT", "ACT"
    add_project a
    add_contact a

    @username = "contact"
    @password = "contact"
  end
end

Given /^the submission of a known (good|checksum mismatch|empty|virus infected) package$/ do |package|
  case package

  when "good"
    @ieid = submit_via_client "ateam"

  when "empty"
    @ieid = submit_via_client "ateam-missing-contentfile"

  when "checksum mismatch"
    @ieid = submit_via_client "ateam-checksum-mismatch"

  when "virus infected"
    @ieid = submit_via_client "ateam-virus"

  end
end

Given /^a workspace$/ do
  setup_workspace
end

When /^ingest is (run|attempted) on that package$/ do |expectation|
  case expectation

  when "run"
    run_ingest @ieid

  when "attempted"
    run_ingest @ieid, false
  end
end

Then /^the package is present in the aip store$/ do
  Aip.get!(@ieid)
end

Then /^there is an operations event for the (\w+)$/ do |event_type|
  case event_type

  when "submission"
    event = OperationsEvent.first(:ieid => @ieid, :event_name => "Package Submission")

  when "ingest"
    pending "ingest doesn't yet add an op event for ingest"

  when "reject"
    pending "ingest doesn't yet add an op event for reject"

  end

  raise "No #{event_type} ops event found" unless event
end

Then /^the package is rejected$/ do
  tag_file_path = File.join ENV["WORKSPACE"], @ieid, "tags", "reject"

  raise "Package not rejected" unless File.exists? tag_file_path
end



