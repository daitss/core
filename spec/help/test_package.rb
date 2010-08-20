require "uuid"

require "daitss/archive"
require "daitss/proc/workspace"
require "daitss/proc/wip/from_sip"
require "daitss/proc/template/premis"

SIPS_DIR = File.join File.dirname(__FILE__), '..', 'sips'

def submit name
  zip_path = File.join SIP_ARCHIVE_DIR, "#{name}.zip"
  raise "sip not found: #{name}.zip" unless File.file? zip_path
  agent = OperationsAgent.first :identifier => 'Bureaucrat'
  a = Archive.new
  sip = a.submit zip_path, agent
  a.workspace[sip.id]
end

def blank_wip id, uri
  path = File.join $sandbox, id
  Wip.new path, uri
end

def pull_aip id
  aip = Aip.get! id
  path = File.join $sandbox, aip.id
  wip = Wip.new path
  wip.load_from_aip
  wip
end

SIP_ARCHIVE_DIR = File.join File.dirname(__FILE__), '..', 'sip_archives'

def new_sip_archive name
  dir = Dir.mktmpdir
  $cleanup << dir
  original_path = File.join SIP_ARCHIVE_DIR, name
  FileUtils.cp original_path, dir
  File.join dir, name
end

def new_workspace
  dir = Dir.mktmpdir
  $cleanup << dir
  Workspace.new dir
end
