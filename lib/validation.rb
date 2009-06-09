require 'cgi'
require 'libxml'
require 'namespace'
require 'util'
require 'open-uri'

include LibXML

class Reject < StandardError
  alias_method :reasons, :message
end

module Ingestable

  def validated?
    events_by_type descriptor, "SIP Validation"
  end

  def validate
    s_url = "http://localhost:4567/?location=#{CGI::escape @url.to_s}"
    results_doc = open(s_url) { |resp| XML::Parser.io(resp).parse }
    descriptor_doc = XML::Parser.file(descriptor).parse
    import_events results_doc, descriptor_doc
    descriptor_doc.save(descriptor)

    # reject if needed
    rr = reject_reasons results_doc
    raise Reject, rr unless rr.empty?
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