require 'service/error'

module Plan
  
  def planned?
    type = "Action Plan Determination"

    md_for(:digiprov).any? do |doc|
      doc.find_first("//premis:event[premis:eventType[normalize-space(.)='#{type}']]", NS_MAP)
    end
    
  end
  
  def plan
    obj_file = md_files_for(:tech).first
    s_url = "http://localhost:4000/instructions?description=#{CGI::escape "file:#{obj_file}" }"
    response = Net::HTTP.get_response URI.parse(s_url)
    
    case response
    when Net::HTTPSuccess
      plan_doc = XML::Parser.string(response.body).parse
      add_md :digiprov, plan_doc
    when Net::HTTPNotFound
      # XXX do nothing, no rxp data here, possibly want to write we tried
    else
      raise ServiceError, "cannot retrieve RXP provenance: #{response.code} #{response.msg}: #{response.body}"
    end
    
  end
    
end