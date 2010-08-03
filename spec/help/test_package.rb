require "workspace"
require "wip/from_sip"
require "template/premis"
require "uuid"

SIPS_DIR = File.join File.dirname(__FILE__), '..', 'sips'

def submit sip_name, workspace=nil
  wip_id = UUID.generate :compact


  workspace = Workspace.new $sandbox if workspace.nil?

  # make the sip
  sip_path = File.join SIPS_DIR, sip_name
  sip = Sip.new sip_path

  # add a sip record
  Dir.chdir sip.path do
    ss = SubmittedSip.new
    ss.package_name = sip.name
    ss.package_size = sip.files.inject(0) { |sum, f| sum + File.size(f) }
    ss.number_of_datafiles = sip.files.size
    ss.ieid = wip_id
    ss.save or raise "cannot make submitted sip"
  end

  # make a staging area
  FileUtils.mkdir_p File.join(workspace.path, '.tmp')

  # make a wip in the staging area
  path = File.join workspace.path, '.tmp', wip_id
  uri = "#{Daitss::CONFIG['uri-prefix']}/#{wip_id}"
  wip = Wip.from_sip path, uri, sip

  wip['submit-event'] = event(:id => "#{wip.uri}/event/submit",
                              :type => 'submit',
                              :outcome => 'success',
                              :linking_objects => [ wip.uri ],
                              :linking_agents => [ 'info:fcla/daitss/reference-submit-client' ])

  wip['submit-agent'] = agent(:id => 'info:fcla/daitss/reference-submit-client',
                              :name => 'daitss submission service',
                              :type => 'software')

  # move the wip into the workspace
  new_path = File.join workspace.path, wip_id
  FileUtils.mv wip.path, new_path
  Wip.new new_path
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
