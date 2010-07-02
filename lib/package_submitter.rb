require 'sip/from_archive'
require 'wip/from_sip'
require 'wip/task'
require 'wip/validation'
require 'wip/submission_metadata'
require 'wip/trim_undescribed'
require 'db/sip'
require 'workspace'
require 'daitss/config'

require 'libxml'
require 'uri'

REJECT_DESCRIPTOR_NOT_FOUND = "SIP descriptor not found"
REJECT_ARCHIVE_EXTRACTION_ERROR = "SIP cannot be extracted"
REJECT_INVALID_DESCRIPTOR = "SIP descriptor failed validation"

REJECT_INVALID_ACCOUNT = "Invalid account"
REJECT_INVALID_PROJECT = "Invalid project"
REJECT_SUBMITTER_DESCRIPTOR_ACCOUNT_MISMATCH = "Submitter account does not match SIP descriptor account"
REJECT_CHECKSUM_MISMATCH = "At least one datafile failed checksum check"
REJECT_MISSING_CONTENT_FILE = "No content files found in SIP"
REJECT_INVALID_PACKAGE_NAME = "Package name is invalid"
REJECT_OBJID_NAME_MISMATCH = "OBJID attribute in root element of descriptor does not match provided package name"
REJECT_INVALID_DATAFILE_NAME = "Datafile present with invalid filename"

class SipReject < StandardError; end
class SipDescriptorInvalid < StandardError; end

class PackageSubmitter

  include Daitss

  CONFIG.load_from_env
  @workspace = Workspace.new CONFIG['workspace']

  URI_PREFIX = CONFIG['uri-prefix']
  SUBMIT_WIP_DIR = File.join @workspace.path, ".submit"

  # creates SIP from submitted archive
  # creates WIP from sip in $WORKSPACE/.submit/PACKAGE_NAME
  # validates WIP, reject if fail
  # writes package metadata
  # writes operations event for submission/reject
  # clean up temp

  def self.submit_sip ieid, package_name, archive_path, ip_addr, submitting_op_agent
    create_submit_dir

    wip_path = File.join SUBMIT_WIP_DIR, ieid
    wip_uri = URI_PREFIX + ieid 

    @errors = []
    @op_event_notes = "submitter_ip: #{ip_addr};"
    @agent = submitting_op_agent

    begin
      sip = Sip.from_archive archive_path, ieid, package_name
      wip = Wip.from_sip wip_path, wip_uri, sip

      raise SipDescriptorInvalid unless wip.sip_descriptor_valid?
    rescue DescriptorNotFoundError
      @errors.push REJECT_DESCRIPTOR_NOT_FOUND
      reject ieid
    rescue ArchiveExtractionError
      @errors.push REJECT_ARCHIVE_EXTRACTION_ERROR
      reject ieid
    rescue LibXML::XML::Error, SipDescriptorInvalid
      @errors.push REJECT_INVALID_DESCRIPTOR
      reject ieid
    else
      validate wip
      reject ieid if @errors.any?
      add_project_to_sip_record wip
      wip.trim_undescribed_datafiles
      write_metadata wip
      wip.task = :ingest
      write_success_op_event ieid
      FileUtils.mv wip_path, File.join(@workspace.path, ieid)
    end
  end

  private

  def self.validate wip
    @errors.push REJECT_INVALID_ACCOUNT unless wip.package_account_valid?
    @errors.push REJECT_INVALID_PROJECT unless wip.package_project_valid?
    @errors.push REJECT_SUBMITTER_DESCRIPTOR_ACCOUNT_MISMATCH unless wip.package_account_matches_agent? @agent
    @errors.push REJECT_CHECKSUM_MISMATCH unless wip.content_file_checksums_match?
    @errors.push REJECT_MISSING_CONTENT_FILE unless wip.content_file_exists?
    @errors.push REJECT_INVALID_PACKAGE_NAME unless wip.package_name_valid?
    @errors.push REJECT_OBJID_NAME_MISMATCH unless wip.obj_id_matches_package_name?
    @errors.push REJECT_INVALID_DATAFILE_NAME unless wip.content_files_have_valid_names?
  end

  def self.write_metadata wip
    wip.create_submit_agent
    wip.create_account_agent
    wip.create_submit_event
    wip.create_accept_event
    wip.create_package_valid_event
  end

  def self.create_submit_dir
    FileUtils.mkdir_p File.join(@workspace.path, ".submit")
  end

  def self.add_project_to_sip_record wip
    sip_record = SubmittedSip.first(:ieid => File.basename(wip.path))
    project = Project.first(:code => wip["dmd-project"])

    sip_record.project = project
    sip_record.save!
  end

  def self.write_success_op_event ieid
    sip_record = SubmittedSip.first(:ieid => ieid)
    @op_event_notes += " outcome: success;"

    event = OperationsEvent.new
    event.attributes = { :timestamp => Time.now,
                         :event_name => "Package Submission",
                         :notes => @op_event_notes }

    event.submitted_sip = sip_record
    event.operations_agent = @agent

    event.save!
  end

  def self.write_reject_op_event ieid
    sip_record = SubmittedSip.first(:ieid => ieid)
    @op_event_notes += " outcome: reject;"

    @errors.each do |error|
      @op_event_notes += " failure reason: #{error};"
    end

    event = OperationsEvent.new
    event.attributes = { :timestamp => Time.now,
                         :event_name => "Package Submission",
                         :notes => @op_event_notes }

    event.submitted_sip = sip_record
    event.operations_agent = @agent

    event.save!
  end

  # deletes temporary wip, writes ops event record for failed submission and raises exception

  def self.reject ieid
    write_reject_op_event ieid
    FileUtils.rm_rf File.join(SUBMIT_WIP_DIR, ieid)
    raise SipReject, @errors.join(", ")
  end

end
