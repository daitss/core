require 'cgi'
require 'libxml'

include LibXML

module Provenance
  
  def provenance_retrieved?
    type = "External Provenance Extraction"
    
    md_for(:digiprov).any? do |doc|
      doc.find_first("//premis:event[premis:eventType[normalize-space(.)='#{type}']]", NS_MAP)
    end
  end

  def retrieve_provenance
    s_url = "http://localhost:7000/provenance/events?location=#{CGI::escape @url.to_s}"
    extp_doc = open(s_url) { |resp| XML::Parser.io(resp).parse }
    add_md :digiprov, extp_doc
  end
  
  def rxp_provenance_retrieved?
    File.exist? rxp_md_file
  end

  def retrieve_rxp_provenance
    s_url = "http://localhost:7000/provenance/rxp?location=#{CGI::escape @url.to_s}"
    rxp_doc = open(s_url) { |resp| XML::Parser.io(resp).parse }
    add_rxp_md rxp_doc
  end
  
  def representations_retrieved?
    type = "Representation Retrieval"
    
    md_for(:digiprov).any? do |doc|
      doc.find_first("//premis:event[premis:eventType[normalize-space(.)='#{type}']]", NS_MAP)
    end
    
  end
  
  def retrieve_representations
    
    s_url = "http://localhost:7000/provenance/representations?location=#{CGI::escape to_s }"
    premis_doc = open(s_url) { |resp| XML::Parser.io(resp).parse }

    # objects
    obj_doc = XML::Document.new
    obj_doc.root = XML::Node.new 'premis'
    obj_doc.root.namespaces.namespace = premis_doc.root.namespaces.namespace

    premis_doc.find("//premis:object", NS_MAP).each do |node|
      obj_doc.root << obj_doc.import(node)
    end

    add_md :tech, obj_doc

    # events & agents
    dp_doc = XML::Document.new
    dp_doc.root = XML::Node.new 'premis'
    dp_doc.root.namespaces.namespace = premis_doc.root.namespaces.namespace

    premis_doc.find("//premis:event", NS_MAP).each do |node|
      dp_doc.root << dp_doc.import(node)
    end

    premis_doc.find("//premis:agent", NS_MAP).each do |node|
      dp_doc.root << dp_doc.import(node)
    end

    add_md :digiprov, dp_doc
    
  end
  
end