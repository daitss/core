require 'fileutils'
require 'wip/create'
require 'template/premis'
require 'submission_history'
require 'uri'
require 'ieid'

class ArchiveExtractionError < StandardError; end

class PackageSubmitter

  URI_PREFIX = "test:/"

  # creates a new aip in the workspace from SIP in a zip or tar file located at path_to_archive.
  # This method:
  #
  # checks DAITSS_WORKSPACE environment var for validity
  # persists a record of the submission, generating a new IEID
  # unarchives the zip/tar to a special place in DAITSS_WORKSPACE
  # makes an AIP from extracted files
  # writes a submission event to package provenance
  # returns new minted IEID of the created AIP

  def self.submit_sip archive_type, path_to_archive, package_name, submitter_ip, md5
    check_workspace
    ieid = Ieid.new.to_s
    persist_request ieid, package_name, submitter_ip, md5

    unarchive_sip archive_type, ieid, path_to_archive, package_name

    wip_path = File.join(ENV["DAITSS_WORKSPACE"], ieid.to_s)
    sip_path = File.join(ENV["DAITSS_WORKSPACE"], ".submit", package_name)

    sip = Sip.new sip_path
    wip = Wip.make_from_sip wip_path, URI.join(URI_PREFIX, ieid), sip

    wip['submit-event'] = event :id => URI.join(wip.uri, 'event', 'submit').to_s, 
      :type => 'submit', 
      :outcome => 'success', 
      :linking_objects => [ wip.uri ],
      :linking_agents => [ 'info:fcla/daitss/submission_service' ]

    wip['submit-agent'] = agent :id => 'info:fcla/daitss/submission_service',
      :name => 'DAITSS 2 submission service', 
      :type => 'software'

    # clean up
    FileUtils.rm_rf sip_path

    return ieid
  end

  private 

  # raises exception if DAITSS_WORKSPACE environment variable is not set to a valid directory on the filesystem

  def self.check_workspace
    raise "DAITSS_WORKSPACE is not set to a valid directory." unless File.directory? ENV["DAITSS_WORKSPACE"]
  end

  # saves a record of the submission to database, generating a new ieid

  def self.persist_request ieid, package_name, submitter_ip, md5
    request = Submission.new

    request.attributes = {  
      :ieid => ieid,
      :package_name => package_name,
      :submission_checksum => md5,
      :timestamp => Time.now,
      :submitter_ip => submitter_ip
    }

    request.save
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

  # unzips/untars specified archive file to $DAITSS_WORKSPACE/.submit/package_name/
  # if the zip/tar file had all files in a single directory inside the archive, files inside are moved one
  #   directory level up 
  # Raises exception if unarchiving tool returns non-zero exit status

  def self.unarchive_sip archive_type, ieid, path_to_archive, package_name
    create_submit_dir unless File.directory? File.join(ENV["DAITSS_WORKSPACE"], ".submit")

    destination = File.join ENV["DAITSS_WORKSPACE"], ".submit", package_name

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

  # creates a .submit directory under DAITSS_WORKSPACE

  def self.create_submit_dir
    FileUtils.mkdir_p File.join(ENV["DAITSS_WORKSPACE"], ".submit")
  end
end
