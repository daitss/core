require "uuid"

require "daitss/archive/submit"
require "daitss/proc/workspace"
require "daitss/proc/wip/from_sip"
require "daitss/proc/template/premis"

SIPS_DIR = File.join File.dirname(__FILE__), '..', 'sips'
DESCRIPTOR_DIR = File.join File.dirname(__FILE__), '..', 'descriptors'

def submit name
  file_name = "#{name}.zip"
  
  begin
    #switch to using online harness files
    zip_path = fixture(file_name)

    raise "sip not found: #{name}.zip" unless File.file? zip_path

    agent = Operator.get(Daitss::Archive::ROOT_OPERATOR_ID) or raise 'cannot get root account'
    a = Daitss.archive
    package = a.submit zip_path, agent

    if package.events.first :name => 'reject'
      raise "test submit failed for #{name}:\n\n#{package.events.last.notes}"
    end
  ensure
    FileUtils.rm zip_path
  end
  
  a.workspace[package.id]
end

def pull_aip id
  aip = Package.get(id).aip or raise "cannot get aip for #{id}"
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
