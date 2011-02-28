require 'xmlns'

# errors that deal with extracting zips or tars
class ExtractionError < StandardError; end

# Provides access to an archive (zip, tar) sip
class SubmissionFile
  extend ActiveSupport::Memoizable

  include ActiveModel::Validations
  validates_with SubmissionValidator

  include LibXML

  #attr_reader :errors

  attr_reader :path, :owner_ids, :agent_account

  AGREEMENT_INFO_XPATH =  "//M:amdSec/M:digiprovMD/M:mdWrap/M:xmlData/daitss:daitss/daitss:AGREEMENT_INFO"

  def initialize upload, account
    @ext = File.extname upload.original_filename
    @name = File.basename upload.original_filename, @ext
    @compressed_path = upload.path
    @tdir = Dir.mktmpdir
    @agent_account = account
  end

  def extract

    command = case @ext
              when '.zip' then unzip_command
              when '.tar' then untar_command
              else raise ExtractionError, "unknown sip extension: #{@ext}"
              end


    Dir.chdir @tdir do
      output = %x[#{command} 2>&1]

      unless $? == 0
        raise ExtractionError, "error extracting #{name}#{@ext}\n\n#{output}"
      end

      @path = File.expand_path @name

      unless File.directory? @path
        raise ExtractionError, "#{@name}#{@ext} does not contain a sip"
      end

    end

  end

  def unzip_command
    %Q(unzip -o "#{@compressed_path}")
  end

  def untar_command
    %Q(tar -xf "#{@compressed_path}")
  end

  def cleanup
    FileUtils.rm_r @tdir
  end

  def extract_owner_ids

    descriptor_doc.find("/M:mets/M:fileSec//M:file[M:FLocat/@xlink:href]", NS_PREFIX).each do |node|
      href = node.find_first('M:FLocat', NS_PREFIX)['href']
      f = URI.unescape href
      @owner_ids[f] = node['OWNERID'] if node['OWNERID']
    end

  end

  # the sum of all the files' size in bytes
  def size_in_bytes

    files.inject(0) do |sum, f|
      path = File.join self.path, f
      sum + File.size(path)
    end

  end
  memoize :size_in_bytes

  def agreement_info_count
    xpath = "count(#{AGREEMENT_INFO_XPATH})"
    descriptor_doc && descriptor_doc.find(xpath, NS_PREFIX)
  end

  def agreement_info
    xpath = "#{AGREEMENT_INFO_XPATH}"
    descriptor_doc && descriptor_doc.find_first(xpath, NS_PREFIX)
  end
  memoize :agreement_info

  def account_id
    agreement_info && agreement_info['ACCOUNT']
  end

  def project_id
    agreement_info && agreement_info['PROJECT']
  end

  def account
    account_id && Account.get(account_id)
  end

  def project
    project_id && account && account.projects.first(:id => project_id)
  end

  def title
    issue_vol_title["title"]
  end

  def issue
    issue_vol_title["issue"]
  end

  def volume
    issue_vol_title["volume"]
  end

  # returns a hash containing issue, volume, and title extracted from sip descriptor
  def issue_vol_title
    return @ivt if @ivt

    @ivt = {}

    #xpath declarations

    dc_title_xpath = "//M:dmdSec//dc:title"
    marc_title_b_xpath = "//M:dmdSec//marc:datafield[@tag='245']/marc:subfield[@code='b']"
    marc_title_a_xpath = "//M:dmdSec//marc:datafield[@tag='245']/marc:subfield[@code='a']"
    marc_issue_vol_xpath = "//M:dmdSec//marc:datafield[@tag='245']/marc:subfield[@code='n']"
    mods_title_xpath = "//M:dmdSec//mods:title"
    mods_issue_xpath = "//mods:part/mods:detail[@type='issue']/mods:number"
    mods_volume_xpath = "//mods:part/mods:detail[@type='volume']/mods:number"
    mods_enum_issue_xpath = "//mods:part/mods:detail[@type='Enum1']/mods:caption"
    mods_enum_volume_xpath = "//mods:part/mods:detail[@type='Enum2']/mods:caption"
    #mods_issue_xpath = "//M:dmdSec//mods:part/mods:detail[@type=issue]/mods:number"
    #mods_volume_xpath = "//M:dmdSec//mods:part/mods:detail[@type=volume]/mods:number"
    structmap_orderlabel_volume_xpath = "//M:structMap//M:div[@TYPE='volume']"
    structmap_orderlabel_issue_xpath = "//M:structMap//M:div[@TYPE='issue']"
    ojs_volume_xpath = "//M:dmdSec[starts-with(@ID, 'I')]/M:mdWrap/M:xmlData/mods:mods/mods:relatedItem/mods:part/mods:detail[@type='volume']/mods:number"
    ojs_issue_xpath = "//M:dmdSec[starts-with(@ID, 'I')]/M:mdWrap/M:xmlData/mods:mods/mods:relatedItem/mods:part/mods:detail[@type='issue']/mods:number"
    is_ojs_xpath = "//M:dmdSec[starts-with(@ID, 'J')]"

    # check if OJS

    if descriptor_doc.find_first(is_ojs_xpath, NS_PREFIX)
      # get title from mods in dmdSec
      title_node = descriptor_doc.find_first mods_title_xpath, NS_PREFIX
      @ivt["title"] = title_node ? title_node.content : nil

      # get OJS volume
      volume_node = descriptor_doc.find_first(ojs_volume_xpath, NS_PREFIX)
      issue_node = descriptor_doc.find_first(ojs_issue_xpath, NS_PREFIX)

      @ivt["volume"] = volume_node ? volume_node.content : nil
      @ivt["issue"] = issue_node ? issue_node.content : nil
      return @ivt
    end

    # check if vol/issue are in structMap
    struct_vol_node = descriptor_doc.find_first(structmap_orderlabel_volume_xpath, NS_PREFIX)
    struct_issue_node = descriptor_doc.find_first(structmap_orderlabel_issue_xpath, NS_PREFIX)

    struct_volume = struct_vol_node["ORDERLABEL"] ? struct_vol_node["ORDERLABEL"] : struct_vol_node["LABEL"] if struct_vol_node
    struct_issue = struct_issue_node["ORDERLABEL"] ? struct_issue_node["ORDERLABEL"] : struct_issue_node["LABEL"] if struct_issue_node

    @ivt["volume"] = struct_volume ? struct_volume : nil
    @ivt["issue"] = struct_issue ? struct_issue : nil

    # look in dmd for title. Also, issue/vol if not found above in structMap

    # mods first
    mods_title_node = descriptor_doc.find_first mods_title_xpath, NS_PREFIX
    @ivt["title"] = mods_title_node ? mods_title_node.content : nil

    unless @ivt["volume"] or @ivt["issue"]
      mods_volume_node = descriptor_doc.find_first mods_volume_xpath, NS_PREFIX
      @ivt["volume"] = mods_volume_node ? mods_volume_node.content : nil

      mods_issue_node = descriptor_doc.find_first mods_issue_xpath, NS_PREFIX
      @ivt["issue"] = mods_issue_node ? mods_issue_node.content : nil

      #try Enum1 and Enum2 if nothing found above
      unless mods_volume_node
        mods_enum_volume_node = descriptor_doc.find_first mods_enum_volume_xpath, NS_PREFIX
        @ivt["volume"] = mods_enum_volume_node ? mods_enum_volume_node.content : nil
      end

      unless mods_issue_node
        mods_enum_issue_node = descriptor_doc.find_first mods_enum_issue_xpath, NS_PREFIX
        @ivt["issue"] = mods_enum_issue_node ? mods_enum_issue_node.content : nil
      end
    end

    # try MARC next
    unless @ivt["title"]
      marc_title_a = descriptor_doc.find_first(marc_title_a_xpath, NS_PREFIX)
      marc_title_b = descriptor_doc.find_first(marc_title_b_xpath, NS_PREFIX)

      marc_title = marc_title_a.content if marc_title_a
      marc_title += " " + marc_title_b.content if marc_title_b

      @ivt["title"] = marc_title ? marc_title : nil

      marc_issue_vol = descriptor_doc.find_first(marc_issue_vol_xpath, NS_PREFIX)

      if marc_issue_vol
        @ivt["volume"] = marc_issue_vol.content[/\d+/]
        @ivt["issue"] = marc_issue_vol.content.gsub(@ivt["volume"], "")[/\d+/]
      end
    end

    # finally, try dublin core
    unless @ivt["title"]
      dc_title_node = descriptor_doc.find_first dc_title_xpath, NS_PREFIX

      if dc_title_node
        dc_title = dc_title_node.content
        dc_volume = nil
        dc_issue = nil

        unless @ivt["volume"] or @ivt["issue"]
          [/Volume\s*\d+/, /vol\.*\s*\d+/, /v\.*\s*\d+/].each do |r|
            if dc_title[r]
              dc_volume = dc_title[r][/\d+/]
              break
            end
          end

          [/Issue\s*\d+/, /no\.*\s*\d+/, /v\.*\s*\d+/].each do |r|
            if dc_title[r]
              dc_issue = dc_title[r][/\d+/]
            end
          end # of each
        end # of if
      end # of unless

      @ivt["title"] = dc_title ? dc_title : nil
      @ivt["volume"] = dc_volume ? dc_volume : nil
      @ivt["issue"] = dc_issue ? dc_issue : nil
    end

    return @ivt
  end # of method issue_volume_title

  def entity_id
    descriptor_doc.root['OBJID']
  end

  def descriptor_doc
    XML::Document.string File.read(descriptor_file) if File.exist? descriptor_file
  end
  memoize :descriptor_doc

  def name
    File.basename @path
  end

  def descriptor_file
    descriptor_file = File.join @path, "#{@name}.xml"
  end

  def content_files_with_data
    ns = descriptor_doc.find "//M:file", NS_PREFIX

    h = {}

    ns.each do |n|

      href = n.find_first("M:FLocat/@xlink:href", NS_PREFIX).value
      path = URI.unescape href
      data = {}

      data[:size] = n['SIZE'] if n['SIZE']


      if n['CHECKSUM']

        # try to infer a checksumtype if its missing
        n['CHECKSUMTYPE'] ||= case n['CHECKSUM']
                              when %r{^[a-fA-F0-9]{32}$} then 'SHA-1'
                              when %r{^[a-fA-F0-9]{40}$} then 'MD5'
                              end

        # if there is a SHA-1 or MD5 use it
        case n['CHECKSUMTYPE']
        when 'SHA-1'
          data[:sha1] = n['CHECKSUM']
        when 'MD5'
          data[:md5] = n['CHECKSUM']
        end

      end

      h[path] = data
    end

    h
  end
  memoize :content_files_with_data

  def content_files
    content_files_with_data.keys
  end

  def files
    [ File.basename(descriptor_file) ] + content_files
  end

  def undescribed_files

    Dir.chdir @path do
      pattern = File.join *%w(** *)
      all_files = Dir[pattern]
      all_files - content_files - [ "#{name}.xml" ]
    end

  end
  memoize :undescribed_files

end
