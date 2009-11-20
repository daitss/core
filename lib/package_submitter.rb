require 'fileutils'
require 'aip'
require 'pp'
require 'libxml'
require 'submission_history'

class ArchiveExtractionError < StandardError; end

class PackageSubmitter

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
    ieid = persist_request package_name, submitter_ip, md5

    unarchive_sip archive_type, ieid, path_to_archive, package_name

    aip_path = File.join(ENV["DAITSS_WORKSPACE"], "aip-#{ieid}")
    sip_path = File.join(ENV["DAITSS_WORKSPACE"], ".submit", package_name)

    aip = Aip.make_from_sip aip_path, sip_path
    submission_event_doc = LibXML::XML::Document.string(create_submission_event(aip_path))

    aip.add_md :digiprov, submission_event_doc

    return ieid
  end

  private 

  # raises exception if DAITSS_WORKSPACE environment variable is not set to a valid directory on the filesystem

  def self.check_workspace
    raise "DAITSS_WORKSPACE is not set to a valid directory." unless File.directory? ENV["DAITSS_WORKSPACE"]
  end

  # saves a record of the submission to database, generating a new ieid

  def self.persist_request package_name, submitter_ip, md5
    request = Submission.new

    request.attributes = {  
      :package_name => package_name,
      :submission_checksum => md5,
      :timestamp => Time.now,
      :submitter_ip => submitter_ip
    }

    request.save

    return request.ieid
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
    if contents.length == 3 and File.directory? File.join(destination, contents[2])
      FileUtils.mv Dir.glob(File.join(destination, "#{contents[2]}/*")), destination
      FileUtils.rm_rf File.join(destination, contents[2])
    end

    raise ArchiveExtractionError, "archive utility exited with non-zero status: #{output}" if $?.exitstatus != 0 
  end

  # returns a string containing the XML for the submission event

  def self.create_submission_event aip_path
    submission_event = <<-event
<premis>
  <event>
    <eventIdentifier>
      <eventIdentifierType>Temporary Local</eventIdentifierType>
      <eventIdentifierValue>1</eventIdentifierValue>
    </eventIdentifier>
    <eventType>Submission</eventType>
    <eventDateTime>#{Time.now.to_s}</eventDateTime>
    <eventOutcomeInformation>
      <eventOutcome>success</eventOutcome>
    </eventOutcomeInformation>
    <linkingAgentIdentifier>
      <linkingAgentIdentifierType>URI</linkingAgentIdentifierType>
      <linkingAgentIdentifierValue>http://daitss/submission</linkingAgentIdentifierValue>
    </linkingAgentIdentifier>
    <linkingObjectIdentifier>
      <linkingObjectIdentifierType>URI</linkingObjectIdentifierType>
      <linkingObjectIdentifierValue>
        file:///#{aip_path}
      </linkingObjectIdentifierValue>
    </linkingObjectIdentifier>
  </event>
 <agent>
   <agentIdentifier>
     <agentIdentifierType>URI</agentIdentifierType>
       <agentIdentifierValue>http://daitss/submission</agentIdentifierValue>
     </agentIdentifier>
   <agentName>DAITSS Submission</agentName>
   <agentType>Web Service</agentType>
 </agent>
</premis>
event

    return submission_event
  end

  # creates a .submit directory under DAITSS_WORKSPACE

  def self.create_submit_dir
    FileUtils.mkdir_p File.join(ENV["DAITSS_WORKSPACE"], ".submit")
  end
end
