require 'template'
require 'wip'

class Wip

  def descriptor
    XML.default_keep_blanks = false
    XML::Document.string template_by_name('aip/descriptor').result(binding)
  end

  private

  def tag_start name, attributes={}
    attr_string = attributes.map { |(a_name, a_value)| "#{a_name.id2name}=\"#{a_value}\"" }.join ' ' 
    "<#{name} #{attr_string}>"
  end

  def tag_end name
    "</#{name}>"
  end

  def tag_single name, attributes={}
    attr_string = attributes.map { |(name, value)| "#{name.id2name}=\"#{value}\"" }.join ' ' 
    "<#{name} #{attr_string}/>"
  end

  def file_element df
    template_by_name('aip/file_element').result binding
  end

  def intellectual_entity_object
    template_by_name('aip/intellectual_entity_object').result binding
  end

  def representation_object rep, options={}
    template_by_name('aip/representation_object').result binding
  end

  def representation_struct_map rep, options={}
    template_by_name('aip/representation_struct_map').result binding
  end

  def md_section doc, options={}
    options[:md_type] ||= 'PREMIS'
    template_by_name('aip/md_section').result binding
  end

end
