require 'wip'
require 'jxml/validator'
require 'libxml'
require 'xmlns'

include LibXML

class Wip

  def cached_datafiles
    @cache_datafiles ||= all_datafiles
  end

  def sip_descriptor_name
    @cache_sip_descriptor_name ||= "#{metadata['sip-name']}.xml"
  end

  # Returns the datafile that described the SIP
  def sip_descriptor
    @cache_sip_descriptor ||= cached_datafiles.find { |df| df['sip-path'] ==  sip_descriptor_name }
  end

  def sip_descriptor_doc
    @cache_sip_descriptor_doc ||= sip_descriptor.open { |io| XML::Document.io io }
  end

  def sip_descriptor_checksum df
    sip_descriptor_datafile_info[df['sip-path']]
  end

  # Returns a list of datafiles that are not the descriptor
  def content_files
    @cache_content_files ||= cached_datafiles.reject { |df| sip_descriptor == df }
  end

  # Returns an array of datafiles that are described in the sip_descriptor
  def described_datafiles
    if sip_descriptor
      sip_paths = sip_descriptor_datafile_info.keys

      cached_datafiles.inject([]) do |acc, df|
        sp = df['sip-path']
        acc << df if sip_descriptor_datafile_info.has_key? sp
        acc
      end

    else
      []
    end
  end

  def validate_sip_descriptor
    xml = sip_descriptor.open { |io| io.read }
    val = JXML::Validator.new
    results = val.validate xml
    @sip_descriptor_errors = results[:errors] + results [:fatals]
  end

  # Returns true if the sip descriptor is valid, false otherwise. errors are aggregated into sip_descriptor_errors
  def sip_descriptor_valid?
    validate_sip_descriptor unless @sip_descriptor_errors
    @sip_descriptor_errors.empty?
  end
  attr_accessor :sip_descriptor_errors

  def sip_descriptor_datafile_info

    @cache_datafile_checksum_info ||= sip_descriptor_doc.find("//M:file", NS_PREFIX).inject({}) do |acc, file_node|
      href_attr = file_node.find_first "M:FLocat/@xlink:href", NS_PREFIX

      if href_attr
        acc[href_attr.value] = { :value => file_node['CHECKSUM'], :type => file_node["CHECKSUMTYPE"] }
      end

      acc
    end

  end

  def sip_descriptor_obj_id
    sip_descriptor_doc.root.attributes["OBJID"]
  end

end
