require 'fileutils'
require 'wip/from_sip'
require 'template/premis'
require 'datafile/checksum'
require 'wip/sip_descriptor'
require 'uri'
require 'libxml'
require 'package_tracker'
require 'xmlns'
require 'wip/task'
require 'db/sip'
require 'workspace'
require 'daitss/config'

class ArchiveExtractionError < StandardError; end
class DescriptorNotFoundError < StandardError; end
class DescriptorCannotBeParsedError < StandardError; end
class SubmitterDescriptorAccountMismatch < StandardError; end
class InvalidProject < StandardError; end
class InvalidAccount < StandardError; end
class InvalidDescriptor < StandardError; end
class ChecksumMismatch < StandardError; end
class MissingContentFile < StandardError; end

class PackageSubmitter
  include Daitss
  CONFIG.load_from_env
  URI_PREFIX = CONFIG['uri-prefix']
  LINKING_AGENTS = [ 'info:fda/daitss/submission_service' ]
  @@workspace = Workspace.new CONFIG['workspace']

  # creates a new aip in the workspace from SIP in a zip or tar file located at path_to_archive.
  # This method:
  #
  # unarchives the zip/tar to a tmp dir in workspace
  # validates SIP descriptor
  # checks that account is valid
  # checks that project is valid in account
  # checks that account of submitter matches account in package descriptor if operator
  # checks for the prescence of at least one content file
  # checks checksums of datafiles against descriptor, if provided
  # inserts an operations event into package tracker
  # makes an AIP from extracted files
  # writes a submission event to package provenance
  # writes a task tag file with "ingest"
  # adds a record for the SIP in the Sip table

  def self.submit_sip archive_type, path_to_archive, package_name, submitter_username, submitter_ip, md5, ieid
    debugger

    pt_event_notes = "submitter_ip: #{submitter_ip}, archive_type: #{archive_type}, submitted_package_checksum: #{md5}"

    unarchive_sip archive_type, ieid, path_to_archive, package_name

    wip_path = File.join(@@workspace.path, ieid.to_s)
    sip_path = File.join(@@workspace.path, ".submit", package_name)

    begin
      sip = Sip.new sip_path
      wip = Wip.from_sip wip_path, URI.join(URI_PREFIX, ieid), sip
      raise InvalidDescriptor unless wip.sip_descriptor_valid?
    rescue Errno::ENOENT
      reject DescriptorNotFoundError.new, pt_event_notes, ieid, submitter_username
    rescue LibXML::XML::Error
      reject DescriptorCannotBeParsedError.new, pt_event_notes, ieid, submitter_username
    rescue InvalidDescriptor
      reject InvalidDescriptor.new(wip.sip_descriptor_errors), pt_event_notes, ieid, submitter_username
    end

    # check that the project in the descriptor exists in the database
    package_account = Account.first(:code => wip["dmd-account"])
    reject InvalidAccount.new, pt_event_notes, ieid, submitter_username unless package_account

    # check that package account in descriptor is specified and matches submitter
    submitter = OperationsAgent.first(:identifier => submitter_username)
    account = submitter.account

    reject SubmitterDescriptorAccountMismatch.new, pt_event_notes, ieid, submitter_username unless account.code == wip["dmd-account"] or submitter.type == Operator

    # check that the project in the descriptor exists in the database
    reject InvalidProject.new, pt_event_notes, ieid, submitter_username unless package_account.projects
    reject InvalidProject.new, pt_event_notes, ieid, submitter_username unless (package_account.projects.map {|project| project.code == wip['dmd-project']}).include? true

    # check for the presence of at least one content file
    reject MissingContentFile.new, pt_event_notes, ieid, submitter_username unless wip.all_datafiles.length > 1

    # check that any specified checksums match descriptor
    checksum_info = wip.described_datafiles.map { |df| [ df['sip-path'] ] + df.checksum_info }
    checksum_info.reject! { |path, desc, comp| desc == nil and comp == nil }
    matches, mismatches = checksum_info.partition { |(path, desc, comp)| desc == comp }
    reject ChecksumMismatch.new, pt_event_notes, ieid, submitter_username if mismatches.any?

    # create premis agents and events in wip
    create_submit_agent wip
    create_account_agent wip
    create_submit_event wip, ieid
    create_package_valid_event wip, ieid

    # add task
    wip.task = :ingest

    # add record to sip table
    add_sip_record package_name, sip_path, ieid

    # write package tracker event
    pt_event_notes = pt_event_notes + ", outcome: success"
    PackageTracker.insert_op_event(submitter_username, ieid, "Package Submission", pt_event_notes)

    # clean up
    FileUtils.rm_rf sip_path
  end

  private

  def self.create_submit_agent wip
    wip['submit-agent'] = agent :id => 'info:fda/daitss/submission_service',
                                :name => 'daitss submission service',
                                :type => 'Software'
  end

  def self.create_account_agent wip
    wip['submit-agent-account'] = agent :id => "info:fda/daitss/accounts/#{wip.metadata["dmd-account"]}",
                                        :name => "DAITSS Account: #{wip.metadata["dmd-account"]}",
                                        :type => 'Affiliate'

    LINKING_AGENTS.push "info:fda/daitss/accounts/#{wip.metadata["dmd-account"]}"
  end

  def self.create_submit_event wip, ieid
    wip['submit-event'] = event :id => "info:fda/#{ieid}/event/submit",
                                :type => 'submit',
                                :outcome => 'success',
                                :linking_objects => [ wip.uri ],
                                :linking_agents => LINKING_AGENTS
  end

  def self.create_package_valid_event wip, ieid
    wip['package-valid-event'] = event :id => "info:fda/#{ieid}/event/package-valid",
                                       :type => 'package valid',
                                       :outcome => 'success',
                                       :linking_objects => [ wip.uri ],
                                       :linking_agents => LINKING_AGENTS
  end

  # adds a record to the Sip table for the sip at sip_path
  def self.add_sip_record package_name, sip_path, ieid
    sip = SubmittedSip.new

    sip_contents = Dir.glob("#{sip_path}/**/*")

    files_in_sip = sip_contents.reject {|path| File.file?(path) == false}
    package_size = sip_contents.inject(0) {|sum, path| sum + File.stat(path).size}

    sip.attributes = { :package_name => package_name,
      :package_size => package_size,
      :number_of_datafiles => files_in_sip.length,
      :ieid => ieid }

    sip.save!
  end

  # writes pt record for failed submission and raises exception

  def self.reject exception, pt_event_notes, ieid, agent_id
    pt_event_notes = pt_event_notes + ", outcome: failure"

    case exception
    when DescriptorNotFoundError
      pt_event_notes = pt_event_notes + ", failure_reason: descriptor not found"
    when DescriptorCannotBeParsedError
      pt_event_notes = pt_event_notes + ", failure_reason: descriptor cannot be parsed"
    when SubmitterDescriptorAccountMismatch
      pt_event_notes = pt_event_notes + ", failure_reason: submitter account does not match descriptor"
    when InvalidAccount
      pt_event_notes = pt_event_notes + ", failure_reason: invalid account"
    when InvalidProject
      pt_event_notes = pt_event_notes + ", failure_reason: invalid project"
    when MissingContentFile
      pt_event_notes = pt_event_notes + ", failure_reason: content file not found"
    when ChecksumMismatch
      pt_event_notes = pt_event_notes + ", failure_reason: datafile failed checksum check against descriptor"
    when ArchiveExtractionError
      pt_event_notes = pt_event_notes + ", failure_reason: sip extraction error"
    when InvalidDescriptor
      pt_event_notes = pt_event_notes + ", failure_reason: descriptor failed validation -- #{exception.message}"
    end

    PackageTracker.insert_op_event(agent_id, ieid, "Package Submission", pt_event_notes)
    raise exception
  end

  # returns string corresponding to unzip command to extract SIP from a zip file

  def self.zip_command_string package_name, path_to_archive, destination
    zip_command = `which unzip`.chomp
    raise "unzip utility not found on this system!" if zip_command =~ /not found/

      return "#{zip_command} -o #{path_to_archive} -d #{destination} 2>&1"
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
    create_submit_dir unless File.directory? File.join(@@workspace.path, ".submit")

    destination = File.join @@workspace.path, ".submit", package_name

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
    FileUtils.mkdir_p File.join(@@workspace.path, ".submit")
  end
end
