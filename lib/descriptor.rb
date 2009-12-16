# Functionality to make a AIP descriptor
module Descriptor

  def descriptor
    template_by_name('aip/descriptor').result binding
  end

  private

  def tag_start name, attributes={}
    attr_string = attributes.map { |(name, value)| "#{name.id2name}=\"#{value}\"" }.join ' ' 
    "<#{name} #{attr_string}>"
  end

  def tag_end name
    "</#{name} #{attr_string}>"
  end

  def tag_single name, attributes={}
    attr_string = attributes.map { |(name, value)| "#{name.id2name}=\"#{value}\"" }.join ' ' 
    "<#{name} #{attr_string}/>"
  end

  def file_element f, id
    template_by_name('aip/file_element').result binding
  end

  def intellectual_entity_object
    template_by_name('aip/intellectual_entity_object').result binding
  end

  def representation_object rep
    template_by_name('aip/representation_object').result binding
  end

  def md_section doc, options={}
    options[:md_type] ||= 'PREMIS'
    template_by_name('aip/md_section').result binding
  end

end
