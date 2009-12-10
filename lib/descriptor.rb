# Functionality to make a AIP descriptor
module Descriptor

  def descriptor
    template = template_by_name 'aip_descriptor'
    template.result binding
  end
  
  def md_section id, doc
    template = template_by_name 'md_section'
    template.result binding
  end

end
