module Monodescriptor
  
  # The final single descriptor file that is stored
  def mono_descriptor_file
    File.join path, MONO_DESCRIPTOR_FILE
  end
  
  def unite_descriptor!

    # map the old ids to new ids
    id_counter = Hash.new { |h, k| h[k] = 0 unless h.has_key? k }
    id_map = Hash.new { |h, k| h[k] = [] unless h.has_key? k }
    doc = XML::Parser.file(poly_descriptor_file).parse

    # change the mdRefs to mdWraps
    doc.find('//mets:amdSec/*/mets:mdRef', NS_MAP).each do |ref|
      location = File.join path, ref['href'] # XXX does namespace matter here?
      md_doc = XML::Parser.file(location).parse
      old_id = ref.parent['ID']

      md_doc.find('/premis:premis/premis:*', NS_MAP).each do |premis_el|
        md_name = ref.parent.name
        md_section = doc.import XML::Node.new(md_name)
        new_id = (id_counter[md_name] += 1).to_s
        md_section['ID'] = md_name.sub(/MD$/, '') + '-' + new_id
        id_map[old_id] << md_section['ID']
        ref.parent.prev = md_section
        wrap = doc.import XML::Node.new('mdWrap')
        wrap['MDTYPE'] = 'PREMIS'
        wrap['LABEL']  = ref['LABEL'] if ref['LABEL']
        md_section << wrap
        xml_data = doc.import XML::Node.new('xmlData')
        wrap << xml_data
        xml_data << doc.import(premis_el)
      end

      ref.parent.remove!
    end

    # update all the ADMIDs  
    doc.find('//mets:*/@ADMID', NS_MAP).each do |admid|
      xpath_result = admid.value.split
      admid.value = xpath_result.map { |xid| id_map[xid].join(" ") }.join(" ")
    end

    XML.indent_tree_output
    doc.save mono_descriptor_file 
  end

end
