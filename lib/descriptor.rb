require 'template'
require 'wip'
require 'datafile'

class Wip

  def descriptor

    @id_map = Hash.new do |hash, key|
      hash[key] = "0"
    end

    def @id_map.method_missing method_id

      key = case method_id
            when :next_tech then :tech
            when :next_digiprov then :digiprov
            else super
            end

      "#{key}-#{self[key].next!}"
    end

    @admid_map = Hash.new { |hash, key| hash[key] = [] }

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

  def digiprov_events

    potential_new_md_keys = [
      'submit-event', 
      'validate-event',
      'ingest-event', 
      'disseminate-event'
    ]

    new_md_keys = potential_new_md_keys.select { |key| metadata.has_key? key }
    new_md_keys.map { |key| metadata[key] } 
  end

end

class DataFile

  def digiprov_events
    
    potential_new_md_keys = [
      'describe-event', 
      'migrate-event',
      'normalize-event'
    ]

    new_md_keys = potential_new_md_keys.select { |key| metadata.has_key? key }
    new_md_keys.map { |key| metadata[key] } 
  end

  def digiprov_agents

    potential_new_md_keys = [
      'describe-agent', 
      'migrate-agent',
      'normalize-agent'
    ]

    new_md_keys = potential_new_md_keys.select { |key| metadata.has_key? key }
    new_md_keys.map { |key| metadata[key] } 
  end

end
