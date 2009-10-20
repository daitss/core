require 'libxml'
include LibXML

Spec::Matchers.define :have_r0_representation do

  match do |descriptor|
    descriptor_doc = XML::Document.file descriptor
    descriptor_doc.find_first "//mets:techMD/mets:mdWrap[@LABEL='R0']/mets:xmlData/premis:object[@xsi:type='representation']", NS_MAP
        
  end

end

Spec::Matchers.define :have_rC_representation do

  match do |descriptor|
    descriptor_doc = XML::Document.file descriptor
    descriptor_doc.find_first "//mets:techMD/mets:mdWrap[@LABEL='RC']/mets:xmlData/premis:object[@xsi:type='representation']", NS_MAP        
  end

end

def transformations descriptor
  # TODO make this work on the tuple id
  h = {}
  
  doc = XML::Document.file descriptor
  
  doc.find('//premis:event[premis:eventType = "Normalization" or premis:eventType = "Migration"]', NS_MAP).each do |event_node|

    node = event_node.find_first 'premis:linkingObjectIdentifier/premis:linkingObjectIdentifierValue', NS_MAP
    src = node.content.strip
    
    node = event_node.find_first 'premis:eventIdentifier/premis:eventIdentifierValue', NS_MAP
    event_id = node.content.strip
    
    puts src, event_id
    # find the object that links to this event
    node = doc.find_first "//premis:object[@xsi:type='file'][premis:linkingEventIdentifier[premis:linkingEventIdentifierValue='#{event_id}']]/premis:objectIdentifier/premis:objectIdentifierValue", NS_MAP
    dst = node.content.strip
    
    # associate them
    h[src] = dst
  end
  
  h
end

def source_files
  transformations(subject).keys
end

def destination_files 
  puts transformations(subject).inspect
  transformations(subject).values
end

def r_0_files descriptor
  doc = XML::Document.file descriptor
  xpath = "/mets:mets/mets:amdSec/mets:techMD/mets:mdWrap[@LABEL='R0']/mets:xmlData/premis:object[@xsi:type='representation']/premis:relationship/premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue"
  doc.find(xpath, NS_MAP).map { |node| node.content.strip }
end

def r_c_files descriptor
  doc = XML::Document.file descriptor
  xpath = "/mets:mets/mets:amdSec/mets:techMD/mets:mdWrap[@LABEL='RC']/mets:xmlData/premis:object[@xsi:type='representation']/premis:relationship/premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue"
  doc.find(xpath, NS_MAP).map { |node| node.content.strip }
end
