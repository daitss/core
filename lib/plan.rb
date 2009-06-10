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
    plan_doc = open(s_url) { |resp| XML::Parser.io(resp).parse }
    add_md :digiprov, plan_doc
  end
    
end