require 'service/error'
require "premismd"

module Service
  
  module Plan

    def planned?
      md_for_event? "Action Plan Determination"    
    end

    def plan!
      obj_file = md_files_for(:tech).first
      s_url = "#{SERVICE_URLS['actionplan']}?description=#{CGI::escape "file:#{obj_file}" }"
      response = Net::HTTP.get_response URI.parse(s_url)

      case response
      when Net::HTTPSuccess
        plan_doc = XML::Parser.string(response.body).parse
        plan_doc.fix_premis_ids! @aip
        dp_md_id = add_md :digiprov, plan_doc
        add_admid_ref dp_md_id
        
      when Net::HTTPNotFound
        # XXX do nothing, no rxp data here, possibly want to write we tried
      else
        raise Service::Error, "cannot action plan determination: #{response.code} #{response.msg}: #{response.body}"
      end

    end
        
  end
  
end