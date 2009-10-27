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
    s_url = "#{Config::Service['validation']}?location=#{CGI::escape @url.to_s}"
        
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
        
    # reject if needed
    if need_to_reject? val_doc
      dp_id = add_md :digiprov, val_doc
      add_div_md_link dp_id
      reasons = reject_reasons val_doc
      raise Reject, reasons unless reasons.empty? # XXX reasons is disjoint from outcome
    else
      strip_cruft! val_doc
      dp_id = add_md :digiprov, val_doc
      add_div_md_link dp_id      
    end 
    
  end

  private

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

  def need_to_reject? doc
    policy_event = doc.find_first("//premis:event[premis:eventType='SIP passed all validation checks']", NS_MAP)
    raise "cannot determine validation of package" unless policy_event
    policy_event.find_first("premis:eventOutcomeInformation[normalize-space(premis:eventOutcome)='failure']", NS_MAP)
  end
  
  def strip_cruft! doc
    
    doc.find("/premis:premis/premis:event[premis:eventType != 'SIP passed all validation checks']", NS_MAP).each do |node|
      node.remove!
    end
    
  end
  
end