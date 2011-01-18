require 'libxml'
require 'daitss/xmlns'
require 'daitss/proc/xmlvalidation'

module Daitss

  # Provides access to an archive (zip, tar) sip
  class SipArchive

    include LibXML

    MAX_NAME_LENGTH = 32

    AGREEMENT_INFO_XPATH =  "//M:amdSec/M:digiprovMD/M:mdWrap/M:xmlData/daitss:daitss/daitss:AGREEMENT_INFO"

    attr_reader :path, :errors, :owner_ids

    def initialize path
      path = File.expand_path path

      filename = File.basename path
      raise "invalid characters in sip name" if filename =~ %r{^\..*['" ]}

      ext = File.extname path
      name = File.basename path, ext

      Dir.chdir File.dirname(path) do

        output = case ext
                 when '.zip' then `unzip -o "#{filename}" 2>&1`
                 when '.tar' then `tar -xf "#{filename}" 2>&1`
                 else raise "unknown archive extension: #{ext}"
                 end

        raise "error extracting #{filename}\n\n#{output}" unless $? == 0
      end

      @name = name
      @path = File.join File.dirname(path), name

      raise "#{filename} is not a package" unless File.directory? @path
    end

    def valid?
      validate! unless @errors
      @errors.empty?
    end

    def validate!
      es = Hash.new { |h,k| h[k] = [] }

      if name.length > MAX_NAME_LENGTH
        es[:package_name] << "package name contains too many characters (#{name.length}) max is #{MAX_NAME_LENGTH}"
      end

      # check for missing descriptor
      es[:descriptor_presence] << "missing descriptor" unless File.file? descriptor_file

      # check for valid descriptor
      if es[:descriptor_presence].empty?
        validation_errors = validate_xml descriptor_file

        unless validation_errors.empty?
          es[:descriptor_valid] << "invalid descriptor"
          es[:descriptor_valid] += validation_errors.map { |e| "#{e[:line]}: #{e[:message]}" }
        end

      end

      # check for a single agreement info
      if es[:descriptor_presence].empty? and es[:descriptor_valid].empty?
        count = descriptor_doc.find "count(#{AGREEMENT_INFO_XPATH})", NS_PREFIX

        if count == 0
          es[:agreement_info] << "missing agreement info"
        elsif count == 1
          ainfo = descriptor_doc.find_first AGREEMENT_INFO_XPATH, NS_PREFIX
          es[:agreement_info] << "missing account" if ainfo['ACCOUNT'].to_s.strip.empty?
          es[:agreement_info] << "missing project" if ainfo['PROJECT'].to_s.strip.empty?
        elsif count > 1
          es[:agreement_info] << "multiple agreement info"
        else
          raise "invalid agreement info count #{count}"
        end

      end

      # check for content files
      if es[:descriptor_presence].empty? and es[:descriptor_valid].empty?
        es[:content_file_presence] << "missing content files" if content_files.empty?

        content_files.each do |f|

          unless Dir.chdir(path) { File.exist? f }
            es[:content_file_presence] << "missing content file: #{f}"
          end

        end
      end

      # check content file name validity
      if es[:descriptor_presence].empty? and es[:descriptor_valid].empty? and es[:content_file_presence].empty?

        content_files.each do |f|
          es[:content_file_name_validity] << "invalid characters in file name: #{f}" if f =~ /^\./
          es[:content_file_name_validity] << "invalid characters in file name: #{f}" if f =~ /['" ]/
        end

      end

      # check content file fixity
      if es[:descriptor_presence].empty? and es[:descriptor_valid].empty? and es[:content_file_presence].empty?

        Dir.chdir @path do

          content_files_with_checksums.each do |f_uri, expected, expected_type|
            f = URI.unescape f_uri

            # try to infer expected type if not provided
            if expected_type.nil? or expected_type.empty?

              expected_type = case expected
                              when %r{^[a-fA-F0-9]{32}$} then 'MD5'
                              when %r{^[a-fA-F0-9]{40}$} then 'SHA-1'
                              end

            end

            # compute the checksum
            computed = case expected_type
                       when "MD5" then Digest::MD5.file(f).hexdigest
                       when "SHA-1" then Digest::SHA1.file(f).hexdigest
                       else next
                       end

            if computed.downcase != expected.downcase
              message = <<MSG
#{expected_type} for #{f}:
  expected: #{expected}
  computed: #{computed}
MSG
              es[:content_file_fixity] << message
            end

          end

        end

      end

      @errors = es.values.flatten
    end

    def extract_owner_ids

      @descriptor_doc.find("/M:mets/M:fileSec//M:file[M:FLocat/@xlink:href]", NS_PREFIX).each do |node|
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


    def account
      xpath = "#{AGREEMENT_INFO_XPATH}/@ACCOUNT"
      node = descriptor_doc.find_first xpath, NS_PREFIX
      node.value rescue nil
    end

    def project
      xpath = "#{AGREEMENT_INFO_XPATH}/@PROJECT"
      node = descriptor_doc.find_first xpath, NS_PREFIX
      node.value rescue nil
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
      @descriptor_doc ||= XML::Document.string File.read(descriptor_file)
    end

    def name
      File.basename @path
    end

    def descriptor_file
      descriptor_file = File.join @path, "#{name}.xml"
    end

    def content_files_with_checksums
      ns = descriptor_doc.find "//M:file", NS_PREFIX

      ns.map do |n|
        href = n.find_first("M:FLocat/@xlink:href", NS_PREFIX).value
        path = URI.unescape href
        cs = n['CHECKSUM']
        cst = n['CHECKSUMTYPE']
        [path, cs, cst]
      end

    end

    def content_files
      ns = descriptor_doc.find "//M:file/M:FLocat/@xlink:href", NS_PREFIX
      ns.map { |n| URI.unescape n.value }
    end

    def files
      [ File.basename(descriptor_file) ] + content_files
    end

    def undescribed_files

      Dir.chdir @path do
        pattern = File.join *%w(** *)
        all_files = Dir[pattern]
        all_files - content_files - [descriptor_file]
      end

    end

  end

end
