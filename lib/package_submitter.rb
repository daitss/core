require 'fileutils'
require 'wip/from_sip'
require 'template/premis'
require 'uri'
require 'old_ieid'
require 'libxml'
require 'package_tracker'

class ArchiveExtractionError < StandardError; end
class DescriptorNotFoundError < StandardError; end
class DescriptorCannotBeParsedError < StandardError; end
class SubmitterDescriptorAccountMismatch < StandardError; end
class InvalidProject < StandardError; end

class PackageSubmitter

  NS_PREFIX = {
    'P' => 'info:lc/xmlns/premis-v2',
    'M' => 'http://www.loc.gov/METS/',
    'xlink' => 'http://www.w3.org/1999/xlink',
    'xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
    'mods' => 'http://www.loc.gov/mods/v3',
    'daitss'=> 'http://www.fcla.edu/dls/md/daitss/'
  }

  URI_PREFIX = "test:/"

  # creates a new aip in the workspace from SIP in a zip or tar file located at path_to_archive.
  # This method:
  #
  # checks WORKSPACE environment var for validity
  # inserts an operations event into package tracker
  # unarchives the zip/tar to a special place in WORKSPACE
  # makes an AIP from extracted files
  # writes a submission event to package provenance
  # returns new minted IEID of the created AIP

  def self.submit_sip archive_type, path_to_archive, package_name, submitter_username, submitter_ip, md5
    check_workspace
    ieid = OldIeid.get_next

    unarchive_sip archive_type, ieid, path_to_archive, package_name

    wip_path = File.join(ENV["WORKSPACE"], ieid.to_s)
    sip_path = File.join(ENV["WORKSPACE"], ".submit", package_name)

    begin
      sip = Sip.new sip_path
      wip = Wip.from_sip wip_path, URI.join(URI_PREFIX, ieid), sip
    rescue Errno::ENOENT
      raise DescriptorNotFoundError
    rescue LibXML::XML::Error
      raise DescriptorCannotBeParsedError
    end

    # check that package account in descriptor is specified and matches submitter
    submitter = OperationsAgent.first(:identifier => submitter_username)
    account = submitter.account

    raise SubmitterDescriptorAccountMismatch unless account.code == wip["dmd-account"] or submitter.type == Operator

    # check that the project in the descriptor exists in the database
    raise InvalidProject unless account.projects
    raise InvalidProject unless account.projects.map {|project| project.code == wip['dmd-project']}.include? true

    wip['submit-agent'] = agent :id => 'info:fcla/daitss/submission_service',
                                :name => 'daitss submission service',
                                :type => 'Software'

    linking_agents = [ 'info:fcla/daitss/submission_service' ]


    wip['submit-agent-account'] = agent :id => "info:fcla/daitss/accounts/#{wip.metadata["dmd-account"]}",
                                        :name => "DAITSS Account: #{wip.metadata["dmd-account"]}",
                                        :type => 'Affiliate'

    linking_agents.push "info:fcla/daitss/accounts/#{wip.metadata["dmd-account"]}"

    wip['submit-event'] = event :id => URI.join(wip.uri, 'event', 'submit').to_s,
      :type => 'submit',
      :outcome => 'success',
      :linking_objects => [ wip.uri ],
      :linking_agents => linking_agents

    # write package tracker event
    submission_event_notes = "submitter_ip: #{submitter_ip}, archive_type: #{archive_type}, submitted_package_checksum: #{md5}"
    PackageTracker.insert_op_event(submitter_username, ieid, "Package Submission", submission_event_notes)

    # clean up
    FileUtils.rm_rf sip_path

    return ieid
  end

  private

  # raises exception if WORKSPACE environment variable is not set to a valid directory on the filesystem

  def self.check_workspace
    raise "The environment variable WORKSPACE is not set to a valid directory." unless File.directory? ENV["WORKSPACE"]
  end

  # returns string corresponding to unzip command to extract SIP from a zip file

  def self.zip_command_string package_name, path_to_archive, destination
    zip_command = `which unzip`.chomp
    raise "unzip utility not found on this system!" if zip_command =~ /not found/

      return "#{zip_command} #{path_to_archive} -d #{destination} 2>&1"
  end

  # returns string corresponding to unzip command to extract SIP from a tar file

  def self.tar_command_string package_name, path_to_archive, destination
    tar_command = `which tar`.chomp
    raise "tar utility not found on this system!" if tar_command =~ /not found/

      return "#{tar_command} -xf #{path_to_archive} -C #{destination} 2>&1"
  end

  # unzips/untars specified archive file to $WORKSPACE/.submit/package_name/
  # if the zip/tar file had all files in a single directory inside the archive, files inside are moved one
  #   directory level up
  # Raises exception if unarchiving tool returns non-zero exit status

  def self.unarchive_sip archive_type, ieid, path_to_archive, package_name
    create_submit_dir unless File.directory? File.join(ENV["WORKSPACE"], ".submit")

    destination = File.join ENV["WORKSPACE"], ".submit", package_name

    if archive_type == :zip
      output = `#{zip_command_string package_name, path_to_archive, destination}`
    elsif archive_type == :tar
      FileUtils.mkdir_p destination
      output = `#{tar_command_string package_name, path_to_archive, destination}`
    else
      raise "Unrecognized archive type"
    end

    contents = Dir.entries destination

    # if package was zipped in a single directory, move files out
    # in general, contents[0] == ".", contents[1] == ".."

    if contents.length == 3 and File.directory? File.join(destination, contents[2])
      FileUtils.mv Dir.glob(File.join(destination, "#{contents[2]}/*")), destination
      FileUtils.rm_rf File.join(destination, contents[2])
    end

    raise ArchiveExtractionError, "archive utility exited with non-zero status: #{output}" if $?.exitstatus != 0
  end

  # creates a .submit directory under WORKSPACE

  def self.create_submit_dir
    FileUtils.mkdir_p File.join(ENV["WORKSPACE"], ".submit")
  end
end
