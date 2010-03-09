require 'libxml'
require 'wip'
require 'xmlns'

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

    Dir.chdir @path do
      Dir['**/*'].select { |f| File.file? f }.map { |f| f }.sort
    end

  end

end

class Wip

  # Create an AIP from a sip
  def Wip.make_from_sip path, uri, sip
    wip = Wip.new path, uri
    wip['sip-name'] = sip.name

    sip.files.each do |f|
      df = wip.new_datafile

      open(File.join(sip.path, f)) do |i| 
        buffer_size = 1024 * 1024 * 10
        buffer = ""

        df.open("w") do |o|

          while i.read(buffer_size, buffer)
            o.write buffer
          end

        end

      end

      df['sip-path'] = f
      df['owner-id'] = sip.owner_ids[f] if sip.owner_ids[f]
    end

    # put metadata from SIP in WIP
    wip.metadata["dmd-account"] = sip.account
    wip.metadata["dmd-project"] = sip.project
    wip.metadata["dmd-title"] = sip.title
    wip.metadata["dmd-issue"] = sip.issue
    wip.metadata["dmd-volume"] = sip.volume
    wip.metadata["dmd-entity-id"] = sip.entity_id
    wip
  end

end
