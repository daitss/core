require 'cgi'
require 'libxml'
require 'namespace'
require 'net/http'

include LibXML

class Reject < StandardError; end

module Service

  module Validate

    def validated?
      metadata.has_key? 'validate'
    end

    def validate!
      url = URI.parse "#{CONFIG['validation']}?location=#{CGI::escape @url.to_s}"
      req = Net::HTTP::Get.new u.request_uri

      res = Net::HTTP.start(u.host, u.port) do |http|
        http.read_timeout = 10 * 60
        http.request(req)
      end

      doc = case res
            when Net::HTTPSuccess then
              XML::Document.string res.body
            else
              raise "cannot validate: #{response.code} #{response.msg}: #{response.body}"
            end

      # TODO fix the ids in the xml

      # reject if needed
      raise Reject, reject_reasons(val_doc) if need_to_reject? val_doc
      strip_cruft! doc
      metadata['validate'] = doc.to_s

    end

    private

    GLOBAL_VALIDATION_EVENT_TYPE = 'SIP passed all validation checks' 

    def reject_reasons doc
      failed_event_xpath = "//P:event[P:eventOutcomeInformation/P:eventOutcome['failure']]"

      reject_reasons = doc.find(failed_event_xpath, NS_PREFIX).map do |fe|
        {
          :type => fe.find_first('P:eventType', NS_PREFIX).content.strip,
          :time => Time.parse(fe.find_first('P:eventDateTime', NS_PREFIX).content.strip),
          :message => fe.find_first('P:eventOutcomeInformation/P:eventOutcome', NS_PREFIX).content.strip
        }
      end

    end

    def need_to_reject? doc
      policy_event = doc.find_first("//P:event[P:eventType='#{GLOBAL_VALIDATION_EVENT_TYPE}']", NS_PREFIX)
      raise "cannot determine validation of package" unless policy_event
      policy_event.find_first("P:eventOutcomeInformation[P:eventOutcome='failure']", NS_PREFIX)
    end

    def strip_cruft! doc
      xpath = "/P:premis/P:event[P:eventType != '#{GLOBAL_VALIDATION_EVENT_TYPE}']"
      doc.find(xpath, NS_PREFIX).each { |node| node.remove! }
    end

  end
end
