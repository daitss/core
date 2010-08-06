require 'libxml'

require 'daitss/db/ops/aip'
require 'daitss/proc/wip'
require 'daitss/xmlns'

include LibXML

class Sip

  attr_reader :path, :owner_ids, :account, :project, :title, :issue, :volume, :entity_id

  def initialize path
    @path = File.expand_path path
    @descriptor_doc = open(descriptor_file) { |io| XML::Document.io io  }
    @owner_ids = {}
    extract_owner_ids

    @account = extract_account
    @project = extract_project
    @title = extract_title
    @volume = extract_volume
    @issue = extract_issue
    @entity_id = extract_entity_id
  end

  def extract_owner_ids

    @descriptor_doc.find("/M:mets/M:fileSec//M:file[M:FLocat/@xlink:href]", NS_PREFIX).each do |node|
      f = node.find_first('M:FLocat', NS_PREFIX)['href']
      @owner_ids[f] = node['OWNERID'] if node['OWNERID']
    end

  end

  def extract_account
    agreement_info_node = @descriptor_doc.find_first("//M:amdSec/M:digiprovMD/M:mdWrap/M:xmlData/daitss:daitss/daitss:AGREEMENT_INFO", NS_PREFIX)

    return agreement_info_node ? agreement_info_node["ACCOUNT"] : nil
  end

  def extract_project
    agreement_info_node = @descriptor_doc.find_first("//M:amdSec/M:digiprovMD/M:mdWrap/M:xmlData/daitss:daitss/daitss:AGREEMENT_INFO", NS_PREFIX)

    return agreement_info_node ? agreement_info_node["PROJECT"] : nil
  end

  def extract_title
   title_node = @descriptor_doc.find_first("//M:dmdSec/M:mdWrap/M:xmlData/mods:mods/mods:titleInfo/mods:title", NS_PREFIX)

    return title_node ? title_node.content : nil
  end

  def extract_issue
    issue_node = @descriptor_doc.find_first("//M:dmdSec/M:mdWrap/M:xmlData/mods:mods/mods:part/mods:detail[@type='issue']/mods:number", NS_PREFIX)

    return issue_node ? issue_node.content : nil
  end

  def extract_volume
    volume_node = @descriptor_doc.find_first("//M:dmdSec/M:mdWrap/M:xmlData/mods:mods/mods:part/mods:detail[@type='volume']/mods:number", NS_PREFIX)

    return volume_node ? volume_node.content : nil
  end

  def extract_entity_id
    root_node = @descriptor_doc.find_first("/M:mets", NS_PREFIX)

    return root_node["OBJID"] ? root_node["OBJID"] : nil
  end

  def descriptor_file
    descriptor_file = File.join @path, "#{name}.xml"
  end

  def name
    File.basename @path
  end

  def files
    ns = @descriptor_doc.find "//M:file/M:FLocat/@xlink:href", NS_PREFIX
    ns.map { |n| n.value } + [File.basename(descriptor_file)]
  end

end

class Wip

  # Create an AIP from a sip
  def Wip.from_sip path, uri, sip
    wip = Wip.new path, uri
    wip['sip-name'] = sip.name

    sip.files.each_with_index do |f, index|
      df = wip.new_original_datafile index

      df.open('w') do |o|
        sip_file_path = File.join sip.path, f
        sip_file_data = File.read sip_file_path
        o.write sip_file_data
      end

      df['sip-path'] = f
      df['aip-path'] = File.join Aip::SIP_FILES_DIR, f
    end

    # put metadata from SIP in WIP
    wip["dmd-account"] = sip.account
    wip["dmd-project"] = sip.project
    wip["dmd-title"] = sip.title
    wip["dmd-issue"] = sip.issue
    wip["dmd-volume"] = sip.volume
    wip["dmd-entity-id"] = sip.entity_id
    wip['sip-descriptor'] = File.read sip.descriptor_file

    wip
  end

end
