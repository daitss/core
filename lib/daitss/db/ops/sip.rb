require 'data_mapper'

class EggHeadKey < DataMapper::Property::String
  key true
  default proc { |res, prop| EggHeadKey.new_egg_head_key }

  # here's how the base string for the ieid is generated:
  # get a floating point representation of the current time
  # convert that floating point number to a string
  # remove the decimal point
  # convert the now decimal point less string into an integer object
  # use Integer's to_s method to get a base 36 representation
  #
  # TODO need something more entropic than time.
  #      payout of improving this is a decent payoff
  # TODO make this automagic for id?
  def EggHeadKey.new_egg_head_key
    string = ::Time.now.to_f.to_s.gsub(".", "").to_i.to_s(36).upcase

    # pad with zeros to 14 characters
    string = ("0" * (14 - string.length)) + string

    # add underscore
    string = string.insert(8, "_")
    return "E" + string
  end

end

class Sip
  include DataMapper::Resource

  property :id, EggHeadKey
  property :name, String
  property :size_in_bytes, Integer, :min => 0, :max => 2**63-1
  property :number_of_datafiles, Integer, :min => 0, :max => 2**63-1

  has n, :operations_events
  has n, :requests
  has 0..1, :aips

  belongs_to :project, :required => false

  def Sip.submit_from_archive workspace, archive_path, id_addr, op_agent
    sip = Sip.new

    wip_path = File.join workspace.submit_dir, sip.id
    wip_uri = URI_PREFIX + sip.id

    @errors = []
    @op_event_notes = "submitter_ip: #{ip_addr};"
    @agent = op_agent

    begin
      sa = SipArchive.from_archive archive_path, sip.id, package_name
      wip = Wip.from_sip wip_path, wip_uri, sa

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
      add_project_to_sip_record wip
      reject ieid if @errors.any?
      wip.trim_undescribed_datafiles
      write_metadata wip
      wip.task = :ingest
      write_success_op_event ieid
      FileUtils.mv wip_path, File.join(@workspace.path, ieid)
    end

  end

end
