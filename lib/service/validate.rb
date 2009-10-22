require 'cgi'
require 'libxml'
require 'namespace'
require 'net/http'
require 'open-uri'
require "premismd"

include LibXML

class Reject < StandardError
  alias_method :reasons, :message
end

module Validate

  def validated?
    md_for_event? "SIP passed all validation checks"    
  end

  def validate!
    s_url = "#{SERVICE_URLS['validation']}?location=#{CGI::escape @url.to_s}"
        
    u = URI.parse s_url
    req = Net::HTTP::Get.new u.request_uri
    response = Net::HTTP.start(u.host, u.port) do |http|
      http.read_timeout = 10 * 60
      http.request(req)
    end
    
    val_doc = case response
    when Net::HTTPSuccess
      XML::Parser.string(response.body).parse
    else
      raise "cannot validate aip: #{response.code} #{response.msg}: #{response.body}"
    end
    
    val_doc.fix_premis_ids! self
    
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