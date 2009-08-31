Spec::Matchers.define :have_r0_representation do

  match do |descriptor|
    descriptor_doc = XML::Document.file descriptor
    descriptor_doc.find_first "//mets:techMD/mets:mdWrap[@LABEL='R0']/mets:xmlData/premis:object[@xsi:type='representation']", NS_MAP
        
  end

end
