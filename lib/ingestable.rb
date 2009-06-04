require 'libxml'
require 'cgi'
require 'namespace'

include LibXML

module Ingestable

  def ingest!
    validate
    #retrieve_provenance
    #process_files
    #aip.store
    #aip.flush_files
  end

  def validate

    # get xml from
    s_url = "http://localhost:4567/?location=#{CGI::escape @url.to_s}"
    results_doc = open(s_url) do |resp|
      parser = XML::Parser.io(resp).parse
    end

    # extract all the events
    events = results_doc.find('//premis:event', NS_MAP)

    # write the results to the descriptor
    descriptor_doc = XML::Parser.file(descriptor).parse

    events.each do |incoming_event|

      event = descriptor_doc.import incoming_event

      # reassign ids, nothing refers to them so its a trivial rename
      if event.find_first('premis:eventIdentifier/premis:eventIdentifierType[normalize-space(.)="Temporary Local"]', NS_MAP)

        begin
          event.find_first('premis:eventIdentifier/premis:eventIdentifierType').content = "daitss 2"
          event.find_first('premis:eventIdentifier/premis:eventIdentifierValue').content = next_event_id descriptor_doc
        rescue
          raise "cannot re-assign identifier to event: #{event}"
        end

      end

      # find or create an amdSec
      amdSec = descriptor_doc.find_first("//mets:amdSec", NS_MAP)

      if amdSec.nil?

        begin
          amdSec = XML::Node.new 'amdSec'
          fileSec = descriptor_doc.find_first("//mets:fileSec", NS_MAP)
          fileSec.prev = amdSec
        rescue
          raise "cannot determine place to insert amdSec"
        end

      end

      # XML ASM FTW?
      # there must be a better way like some application of XSLT
      mdWrap = XML::Node.new 'mdWrap'
      mdWrap['MDTYPE'] = 'PREMIS'
      amdSec << mdWrap
      xmlData = XML::Node.new 'xmlData'
      mdWrap << xmlData
      xmlData << event
    end

    # save it
    descriptor_doc.save(descriptor)

    # reject if needed
    rr = reject_reasons results_doc
    raise Reject, rr unless rr.empty?

  end

  def retrieve_provenance
    s_url = "http://localhost:4567/external_provenance?location=#{CGI::escape @url.to_s}"
    results = open(s_url) { |r| r.read }
  end

  def process_files
    new_files = []

    aip.files.each do |file|
      file.describe!
      file.plan!
      new_files << file.transform if file.has_transformation?
    end

  end

  def store
  end

  def flush_files
  end

  protected

  def reject_reasons doc

    failed_event_xpath = "//premis:event[premis:eventOutcomeInformation/premis:eventOutcome[normalize-space(.)='failure']]"
    reject_reasons = doc.find(failed_event_xpath, NS_MAP).map do |fe|
      {
        :type => fe.find_first('premis:eventType', NS_MAP).content.strip,
        :time => Time.parse(fe.find_first('premis:eventDateTime', NS_MAP).content.strip),
        :message => fe.find_first('premis:eventOutcomeInformation/premis:eventOutcome', NS_MAP).content.strip
      }
    end

  end

end
