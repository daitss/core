require 'db/operations_agents'
require 'db/operations_events'
require 'db/aip'
require 'daitss/config'
require 'helper'

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

def run_ingest ieid
  raise "No IEID to ingest" unless ieid

  output = `#{INGEST_BIN_PATH} #{ieid}`
  raise "Ingest seems to have failed: #{output}" unless $?.exitstatus == 0
end

Given /^an archive (\w+)$/ do |actor|

  case actor

  when "operator"
    a = add_account
    add_operator a

    @username = "operator"
    @password = "operator"

  when "contact"
    a = add_account "ACT", "ACT"
    add_contact a

    @username = "contact"
    @password = "contact"
  end
end

Given /^the submission of a known good package$/ do
  @ieid = submit_via_client "ateam"
end

When /^ingest is run on that package$/ do
  run_ingest @ieid
end

Then /^the package is present in the aip store$/ do
  Aip.get!(@ieid)
end

Then /^there is an operations event for the submission$/ do
  event = OperationsEvent.first(:ieid => @ieid, :event_name => "Package Submission")

  raise "No submission ops event found" unless event
end

Then /^there is an operations event for the ingest$/ do
  pending "ingest doesn't yet add an op for Ingest"
end


