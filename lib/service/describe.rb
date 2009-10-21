require 'namespace'
require 'next'

module Service
  
  module Describe

    def described?
      md_for_event? "Format Description"
    end
    
    def describe! t_event=nil
      s_url = "#{SERVICE_URLS['description']}?location=#{CGI::escape to_s}"
      response = Net::HTTP.get_response URI.parse(s_url)
    
      premis_doc = case response
                   when Net::HTTPSuccess
                     XML::Parser.string(response.body).parse
                   else
                     raise Error, "cannot describe file: #{response.code} #{response.msg}: #{response.body}"
                   end

      fix_identifiers premis_doc
      
      # objects
      obj_doc = XML::Document.new
      obj_doc.root = XML::Node.new 'premis'
      ns = XML::Namespace.new(obj_doc.root, "premis", NS_MAP['premis'])
      obj_doc.root.namespaces.namespace = ns
      
      premis_doc.find("//premis:object[@xsi:type='file']", NS_MAP).each do |node|
                
        # if this object is the product of a transformation, then add a linking event identifier
        if t_event
          lei = XML::Node.new('linkingEventIdentifier')
          lei << (XML::Node.new('linkingEventIdentifierType') << t_event[:type])
          lei << (XML::Node.new('linkingEventIdentifierValue') << t_event[:value])
          
          insertion_point = node.find_first "premis:linkingIntellectualEntityIdentifier|premis:linkingRightsStatementIdentifier", NS_MAP
          
          if insertion_point
            insertion_point.prev = premis_doc.import(lei)
          else
            node << premis_doc.import(lei)
          end
          
        end
        
        obj_doc.root << obj_doc.import(node)
      end

      tech_md_id = add_md :tech, obj_doc
      add_admid_ref tech_md_id

      # events & agents
      dp_doc = XML::Document.new
      dp_doc.root = XML::Node.new 'premis'
    
      ns = XML::Namespace.new(dp_doc.root, "premis", NS_MAP['premis'])
      dp_doc.root.namespaces.namespace = ns

      premis_doc.find("//premis:event", NS_MAP).each { |node| dp_doc.root << dp_doc.import(node) }
      premis_doc.find("//premis:agent", NS_MAP).each { |node| dp_doc.root << dp_doc.import(node) }

      dp_md_id = add_md :digiprov, dp_doc
      add_admid_ref dp_md_id
    end
  
    def format_known?

      not md_for(:tech).any? do |doc|
        doc.find_first("//premis:formatName[normalize-space(.)='unknown']", NS_MAP)
      end

    end

    private
   
    # event ids are global to the package
    # one file object should exist, id from the data file
    # bitstream objects should be fileid/n 
    def fix_identifiers doc
      
      # file ##################
      # assuming there is one file here
      
      # incoming id of the file
      old_fid_node = doc.find_first("//premis:object[@xsi:type='file']/premis:objectIdentifier", NS_MAP)
      old_f_type = old_fid_node.find_first("premis:objectIdentifierType", NS_MAP).content.strip
      old_f_value = old_fid_node.find_first("premis:objectIdentifierValue", NS_MAP).content.strip

      doc.find("//premis:object[@xsi:type='bitstream' or @xsi:type='file']/premis:objectIdentifier", NS_MAP).each do |obj_id_node|
        t_node = obj_id_node.find_first("premis:objectIdentifierType", NS_MAP)
        v_node = obj_id_node.find_first("premis:objectIdentifierValue", NS_MAP)
        
        old_t = t_node.content.strip
        old_v = v_node.content.strip
        
        t_node.content = 'd2'
        v_node.content = old_v.sub old_f_value, fid

        puts obj_id_node.to_s

        doc.find("//premis:linkingObjectIdentifer[premis:linkingObjectIdentifierType = '#{old_t}' and premis:linkingObjectIdentifierValue = '#{old_v}']", NS_MAP).each do |link_node|
          link_node.find_first("premis:linkingObjectIdentifierType", NS_MAP).content = t_node.content
          link_node.find_first("premis:linkingObjectIdentifierValue", NS_MAP).content = v_node.content
        end
        
      end
            
      # events ################
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