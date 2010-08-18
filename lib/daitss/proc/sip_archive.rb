require 'libxml'
require 'daitss/xmlns'

include LibXML

# Provides access to an archive (zip, tar) sip
class SipArchive

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
require 'daitss/proc/tempdir'

require 'daitss/proc/wip/from_sip'
require 'daitss/db/ops'

class ArchiveExtractionError < StandardError; end
class DescriptorNotFoundError < StandardError; end

class Sip

  # extracts sip file from zip, tar, or gzip file, creates record in sip table, and returns a Sip object

  def Sip.from_archive path_to_archive, ieid, package_name

    # write record to sip table
    sip = SubmittedSip.new
    sip.attributes = { :package_name => package_name,
                       :ieid => ieid }
    sip.save!

    # detect archive type
    type = detect_archive_type path_to_archive

    # extract from archive
    sip_path = extract_archive path_to_archive, type, package_name
    update_sip_record sip, sip_path

    # create sip object
    begin
      return Sip.new sip_path
    rescue Errno::ENOENT
      raise DescriptorNotFoundError
    end
  end

  private

  def Sip.update_sip_record sip_record, sip_path
    sip_contents = Dir.glob("#{sip_path}/**/*")

    files_in_sip = sip_contents.reject {|path| File.file?(path) == false}
    package_size = sip_contents.inject(0) {|sum, path| sum + File.stat(path).size}

    sip_record.attributes = {
      :package_size => package_size,
      :number_of_datafiles => files_in_sip.length
       }

    sip_record.save!
  end

  def Sip.detect_archive_type path_to_archive
    file_string = `file #{path_to_archive}`

    if file_string =~ /tar/i
      :tar
    elsif file_string =~ /zip/i
      :zip
    else
      raise ArchiveExtractionError, "Can't determine archive type"
    end
  end

  def Sip.extract_archive path_to_archive, type, package_name

    unarchive_destination = Tempdir.new
    sip_path = File.join unarchive_destination.path, package_name

    case type

    when :tar
      tar_command = `which tar`.chomp
      raise ArchiveExtractionError, "tar utility not found on this system!" if tar_command =~ /not found/
      command = "#{tar_command} -xf #{path_to_archive} -C #{unarchive_destination.path} 2>&1"

    when :zip
      zip_command = `which unzip`.chomp
      raise ArchiveExtractionError, "unzip utility not found on this system!" if zip_command =~ /not found/
      command = "#{zip_command} -o #{path_to_archive} -d #{unarchive_destination.path} 2>&1"
    end

    output = `#{command}`
    raise ArchiveExtractionError, "Extraction utility returned non-zero exit status: #{output}" unless $?.exitstatus == 0
    raise ArchiveExtractionError, "SIP not in #{package_name} subdirectory" unless File.directory? sip_path

   return sip_path
  end
end
