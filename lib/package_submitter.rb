require 'fileutils'
require 'wip/create'
require 'template/premis'
require 'uri'
require 'ieid'
require 'libxml'
require 'package_tracker'

class ArchiveExtractionError < StandardError; end
class DescriptorNotFoundError < StandardError; end
class DescriptorCannotBeParsedError < StandardError; end

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
  # checks DAITSS_WORKSPACE environment var for validity
  # inserts an operations event into package tracker
  # unarchives the zip/tar to a special place in DAITSS_WORKSPACE
  # makes an AIP from extracted files
  # writes a submission event to package provenance
  # returns new minted IEID of the created AIP

  def self.submit_sip archive_type, path_to_archive, package_name, submitter_username, submitter_ip, md5
    check_workspace
    ieid = Ieid.new.to_s

    unarchive_sip archive_type, ieid, path_to_archive, package_name

    wip_path = File.join(ENV["DAITSS_WORKSPACE"], ieid.to_s)
    sip_path = File.join(ENV["DAITSS_WORKSPACE"], ".submit", package_name)

    begin
      sip = Sip.new sip_path
      wip = Wip.make_from_sip wip_path, URI.join(URI_PREFIX, ieid), sip
    rescue Errno::ENOENT
      raise DescriptorNotFoundError
    rescue LibXML::XML::Error
      raise DescriptorCannotBeParsedError
    end

    int_entity_metadata = extract_int_entity wip, package_name

    wip['submit-event'] = event :id => URI.join(wip.uri, 'event', 'submit').to_s, 
      :type => 'submit', 
      :outcome => 'success', 
      :linking_objects => [ wip.uri ],
      :linking_agents => [ 'info:fcla/daitss/submission_service' ]

    wip['submit-agent'] = agent :id => 'info:fcla/daitss/submission_service',
      :name => 'daitss submission service', 
      :type => 'software'

    wip.metadata['dmd-title'] = int_entity_metadata["title"] if int_entity_metadata["title"]
    wip.metadata['dmd-issue'] = int_entity_metadata["issue"] if int_entity_metadata["issue"]
    wip.metadata['dmd-volume'] = int_entity_metadata["volume"] if int_entity_metadata["volume"]
    wip.metadata['dmd-account'] = int_entity_metadata["account"] if int_entity_metadata["account"]
    wip.metadata['dmd-project'] = int_entity_metadata["project"] if int_entity_metadata["project"]

    # write package tracker event
    submission_event_notes = "submitter_ip: #{submitter_ip}, archive_type: #{archive_type}, submitted_package_checksum: #{md5}"
    PackageTracker.insert_op_event(submitter_username, ieid, "Package Submission", submission_event_notes) 

    # clean up
    FileUtils.rm_rf sip_path

    return ieid
  end

  private 

  # raises exception if DAITSS_WORKSPACE environment variable is not set to a valid directory on the filesystem

  def self.check_workspace
    raise "DAITSS_WORKSPACE is not set to a valid directory." unless File.directory? ENV["DAITSS_WORKSPACE"]
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

  # look for SIP descriptor and attempt to extract intellectual entity metadata (volume, issue, title, daitss account, daitss project)

  def self.extract_int_entity wip, package_name
    sip_descriptor = nil 
    metadata = {}

    wip.datafiles.each do |datafile|
      if datafile.metadata["sip-path"].downcase == "#{package_name}.xml".downcase
        sip_descriptor = LibXML::XML::Document.io datafile.open
      end
    end

    metadata["title"] = find_title sip_descriptor
    metadata["volume"] = find_volume sip_descriptor
    metadata["issue"] = find_issue sip_descriptor
    metadata["account"] = find_account sip_descriptor
    metadata["project"] = find_project sip_descriptor

    return metadata
  end

  # runs xpaths for supported dmd encoding standards for title on SIP descriptor. returns nil if none match
  # TODO: this should also support dublin core

  def self.find_title sip_descriptor
    title = sip_descriptor.find_first("//M:dmdSec/M:mdWrap/M:xmlData/mods:mods/mods:titleInfo/mods:title", NS_PREFIX)

    return title ? title.content : nil
  end

  # runs xpaths for supported dmd encoding standards for issue on SIP descriptor. returns nil if none match
  # TODO: this should also support dublin core

  def self.find_issue sip_descriptor
    issue = sip_descriptor.find_first("//M:dmdSec/M:mdWrap/M:xmlData/mods:mods/mods:part/mods:detail[@type='issue']/mods:number", NS_PREFIX)

    return issue ? issue.content : nil
  end

  # runs xpaths for supported dmd encoding standards for volume on SIP descriptor. returns nil if none match
  # TODO: this should also support dublin core

  def self.find_volume sip_descriptor
    volume = sip_descriptor.find_first("//M:dmdSec/M:mdWrap/M:xmlData/mods:mods/mods:part/mods:detail[@type='volume']/mods:number", NS_PREFIX)

    return volume ? volume.content : nil
  end

  # runs xpaths for DAITSS account on SIP descriptor. returns nil if none match
  def self.find_account sip_descriptor
    agreement_info_node = sip_descriptor.find_first("//M:amdSec/M:digiprovMD/M:mdWrap/M:xmlData/daitss:daitss/daitss:AGREEMENT_INFO", NS_PREFIX)
    return agreement_info_node ? agreement_info_node["ACCOUNT"] : nil
  end

  # runs xpaths for DAITSS project on SIP descriptor. returns nil if none match
  def self.find_project sip_descriptor
    agreement_info_node = sip_descriptor.find_first("//M:amdSec/M:digiprovMD/M:mdWrap/M:xmlData/daitss:daitss/daitss:AGREEMENT_INFO", NS_PREFIX)
    return agreement_info_node ? agreement_info_node["PROJECT"] : nil
  end

  # creates a .submit directory under DAITSS_WORKSPACE

  def self.create_submit_dir
    FileUtils.mkdir_p File.join(ENV["DAITSS_WORKSPACE"], ".submit")
  end
end
