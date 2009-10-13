require 'namespace'

module Service
  
  module Describe

    def described?
      md_for_event? "Format Description"
    end
    
    def describe! t_event=nil
      s_url = "#{SERVICE_URLS['description']}?location=#{CGI::escape to_s }"
      response = Net::HTTP.get_response URI.parse(s_url)
    
      premis_doc = case response
      when Net::HTTPSuccess
        XML::Parser.string(response.body).parse
      else
        raise Error, "cannot describe file: #{response.code} #{response.msg}: #{response.body}"
      end

      # objects
      obj_doc = XML::Document.new
      obj_doc.root = XML::Node.new 'premis'
      ns = XML::Namespace.new(obj_doc.root, "premis", NS_MAP['premis'])
      obj_doc.root.namespaces.namespace = ns

      premis_doc.find("//premis:object", NS_MAP).each do |node|
        
        # set the premis id
        node.find_first("premis:objectIdentifier/premis:objectIdentifierType", NS_MAP).content = 'd2'
        node.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NS_MAP).content = fid
        
        # if this object is the product of a transformation, then add a linking event identifier
        if t_event
          lei = XML::Node.new('premis:linkingEventIdentifier')
          lei << (XML::Node.new('premis:linkingEventIdentifierType') << t_event[:type])
          lei << (XML::Node.new('premis:linkingEventIdentifierValue') << t_event[:value])
          
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

      premis_doc.find("//premis:event", NS_MAP).each do |node|
        # TODO set the premis id to something
        
        # set the linking object identifier
        node.find_first("premis:linkingObjectIdentifier/premis:linkingObjectIdentifierType", NS_MAP).content = 'd2'
        node.find_first("premis:linkingObjectIdentifier/premis:linkingObjectIdentifierValue", NS_MAP).content = fid
        
        dp_doc.root << dp_doc.import(node)
      end

      premis_doc.find("//premis:agent", NS_MAP).each do |node|
        dp_doc.root << dp_doc.import(node)
      end

      dp_md_id = add_md :digiprov, dp_doc
      add_admid_ref dp_md_id
    end
  
  def describe_with_transformation! transformation
  end
  
    def format_known?
    
      not md_for(:tech).any? do |doc|
        doc.find_first("//premis:formatName[normalize-space(.)='unknown']", NS_MAP)
      end
    
    end
  
  end
  
end