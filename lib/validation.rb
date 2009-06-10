require 'cgi'
require 'libxml'
require 'namespace'
require 'open-uri'

include LibXML

class Reject < StandardError
  alias_method :reasons, :message
end

module Validate

  def validated?
    type = "SIP Validation"
    
    md_for(:digiprov).any? do |doc|
      doc.find_first("//premis:event[premis:eventType[normalize-space(.)='#{type}']]", NS_MAP)
    end
  end

  def validate
    s_url = "http://localhost:4567/?location=#{CGI::escape @url.to_s}"
    puts s_url
    val_doc = open(s_url) { |resp| XML::Parser.io(resp).parse }
    add_md :digiprov, val_doc

    # reject if needed
    policy_event = val_doc.find_first("//premis:event[premis:eventType='SIP passed all validation checks']", NS_MAP) 

    if policy_event
      outcome = policy_event.find_first("premis:eventOutcomeInformation/premis:eventOutcome", NS_MAP).content.strip
      
      if outcome == 'failure'
        reasons = reject_reasons val_doc
        raise Reject, reasons unless reasons.empty?
      end
      
    else
      raise "cannot determine validation of package"
    end
    
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