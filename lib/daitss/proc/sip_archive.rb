require 'libxml'
require 'daitss/xmlns'

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
      raise "invalid characters in sip name" if filename =~ /^\..*['" ]/

        ext = File.extname path
      name = File.basename path, ext

      Dir.chdir File.dirname(path) do

        output = case ext
                 when '.zip' then `unzip -o #{filename} 2>&1`
                 when '.tar' then `tar -xf #{filename} 2>&1`
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
        xml = File.read descriptor_file
        val = JXML::Validator.new
        results = val.validate xml
        validation_errors = results[:errors] + results[:fatals]

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
          es[:content_file_name_validity] << "invalid characters in file name: #{f}" if f =~ /^\..*['" ]/
        end

      end

      # check content file fixity
      if es[:descriptor_presence].empty? and es[:descriptor_valid].empty? and es[:content_file_presence].empty?

        Dir.chdir @path do

          content_files_with_checksums.each do |f, expected, expected_type|

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
              es[:content_file_fixity] << "#{expected_type} for #{f} - expected: #{expected}; computed #{computed}"
            end

          end

        end

      end

      @errors = es.values.flatten
    end

    def extract_owner_ids

      @descriptor_doc.find("/M:mets/M:fileSec//M:file[M:FLocat/@xlink:href]", NS_PREFIX).each do |node|
        f = node.find_first('M:FLocat', NS_PREFIX)['href']
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
      xpath = "//M:dmdSec/M:mdWrap/M:xmlData/mods:mods/mods:titleInfo/mods:title"
      node = descriptor_doc.find_first xpath, NS_PREFIX
      node.content rescue nil
    end

    def issue
      xpath = "//M:dmdSec/M:mdWrap/M:xmlData/mods:mods/mods:part/mods:detail[@type='issue']/mods:number"
      node = descriptor_doc.find_first xpath, NS_PREFIX
      node.content rescue nil
    end

    def volume
      xpath = "//M:dmdSec/M:mdWrap/M:xmlData/mods:mods/mods:part/mods:detail[@type='volume']/mods:number"
      node = descriptor_doc.find_first xpath, NS_PREFIX
      node.content rescue nil
    end

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
        path = n.find_first("M:FLocat/@xlink:href", NS_PREFIX).value
        cs = n['CHECKSUM']
        cst = n['CHECKSUMTYPE']
        [path, cs, cst]
      end

    end

    def content_files
      ns = descriptor_doc.find "//M:file/M:FLocat/@xlink:href", NS_PREFIX
      ns.map { |n| n.value }
    end

    def files
      [ File.basename(descriptor_file) ] + content_files
    end

  end

end
