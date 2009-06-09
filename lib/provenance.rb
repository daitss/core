require 'cgi'
require 'libxml'
require 'util'

include LibXML

module Ingestable
  
  def provenance_retrieved?
    events_by_type descriptor, "External Provenance Extraction"
  end

  def retrieve_provenance
    s_url = "http://localhost:4567/external_provenance?location=#{CGI::escape @url.to_s}"
    results_doc = open(s_url) { |resp| XML::Parser.io(resp).parse }
    descriptor_doc = XML::Parser.file(descriptor).parse
    
    import_events results_doc, descriptor_doc
    descriptor_doc.save descriptor
  end
  
end