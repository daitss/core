require "namespace"

# fix premis ids to a package
module LibXML
  
  module XML
    
    class Document
      
      def fix_premis_ids! aip
        fix_object_ids aip
        fix_event_ids aip
      end
      
      private
            
      def fix_object_ids aip
        
        find("premis:object[@xsi:type='file']", NS_MAP).each do |file_node|
          
          # the old file node
          old_fid_node = find_first("//premis:object[@xsi:type='file']/premis:objectIdentifier", NS_MAP)
          old_f_type = old_fid_node.find_first("premis:objectIdentifierType", NS_MAP).content.strip
          old_f_value = old_fid_node.find_first("premis:objectIdentifierValue", NS_MAP).content.strip
          
          new_f_type = 'd2'
          new_f_value = file_id_map(aip)[old_f_value]
          
          find("//premis:object[@xsi:type='bitstream' or @xsi:type='file']/premis:objectIdentifier", NS_MAP).each do |obj_id_node|
            t_node = obj_id_node.find_first("premis:objectIdentifierType", NS_MAP)
            v_node = obj_id_node.find_first("premis:objectIdentifierValue", NS_MAP)

            old_t = t_node.content.strip
            old_v = v_node.content.strip

            t_node.content = new_f_type
            v_node.content = old_v.sub old_f_value, new_f_value

            find("//premis:linkingObjectIdentifier[premis:linkingObjectIdentifierType = '#{old_t}' and premis:linkingObjectIdentifierValue = '#{old_v}']", NS_MAP).each do |link_node|
              link_node.find_first("premis:linkingObjectIdentifierType", NS_MAP).content = t_node.content
              link_node.find_first("premis:linkingObjectIdentifierValue", NS_MAP).content = v_node.content
            end

          end
          
        end
        
      end
      
      def fix_event_ids(aip)
        event_id_index = next_event_id_index(aip)

        find("//premis:eventIdentifier", NS_MAP).each do |event_id_node|
          t_node = event_id_node.find_first("premis:eventIdentifierType", NS_MAP)
          v_node = event_id_node.find_first("premis:eventIdentifierValue", NS_MAP)

          old_t = t_node.content.strip
          old_v = v_node.content.strip

          t_node.content = 'd2'
          v_node.content = "event-#{event_id_index}"

          find("//premis:linkingEventIdentifier[premis:linkingEventIdentifierType = '#{old_t}' and premis:linkingEventIdentifierValue = '#{old_v}']", NS_MAP).each do |link_node|
            link_node.find_first("premis:linkingEventIdentifierType", NS_MAP).content = t_node.content
            link_node.find_first("premis:linkingEventIdentifierValue", NS_MAP).content = v_node.content
          end

          event_id_index += 1
        end
        
      end
      
      def file_id_map aip
        
        aip.files.inject({}) do |acc, file|
          acc[file.url.path] = file.fid
          acc
        end
        
      end
      
      def next_event_id_index(aip)
        dp_domain = aip.files
        dp_domain.unshift aip
        dp_docs = dp_domain.map { |e| e.md_for(:digiprov) }.flatten
        xpath = "//premis:eventIdentifier[premis:eventIdentifierType = 'd2']/premis:eventIdentifierValue"
        event_ids = dp_docs.map { |doc| doc.find(xpath, NS_MAP).map { |e| e.content.strip } }.flatten
        event_ids.next_in %r{event-(\d+)}
      end
            
    end
    
  end
  
end