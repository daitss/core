require 'service/error'

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
        fix_identifiers plan_doc
        dp_md_id = add_md :digiprov, plan_doc
        add_admid_ref dp_md_id
        
      when Net::HTTPNotFound
        # XXX do nothing, no rxp data here, possibly want to write we tried
      else
        raise Service::Error, "cannot action plan determination: #{response.code} #{response.msg}: #{response.body}"
      end

    end
    
    private
    
    def fix_identifiers doc
      event_id_index = next_event_id_index

      doc.find("//premis:eventIdentifier", NS_MAP).each do |event_id_node|
        t_node = event_id_node.find_first("premis:eventIdentifierType", NS_MAP)
        v_node = event_id_node.find_first("premis:eventIdentifierValue", NS_MAP)

        old_t = t_node.content.strip
        old_v = v_node.content.strip

        t_node.content = 'd2'
        v_node.content = "event-#{event_id_index}"

        # TODO links to this event
        doc.find("//premis:linkingEventIdentifer[premis:linkingEventIdentifierType = '#{old_t}' and premis:linkingEventIdentifierValue = '#{old_v}']", NS_MAP).each do |link_node|
          link_node.find_first("premis:linkingEventIdentifierType", NS_MAP).content = t_node.content
          link_node.find_first("premis:linkingEventIdentifierValue", NS_MAP).content = v_node.content
        end

        event_id_index += 1
      end

    end

    def next_event_id_index

      event_ids = @aip.files.inject([]) do |acc,f|

        l = f.md_for(:digiprov).map do |doc|
          xpath = "//premis:event/premis:eventIdentifier[premis:eventIdentifierType = 'd2']/premis:eventIdentifierValue"
          doc.find(xpath, NS_MAP).map { |e| e.content.strip }
        end

        acc + l.flatten            
      end

      event_ids.next_in %r{event-(\d+)}
    end
    
  end
  
end