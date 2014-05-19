require 'daitss/proc/wip'
require 'daitss/proc/wip/journal'
require 'daitss/service/xmlres'
require 'daitss/proc/datafile/describe'
require 'daitss/proc/datafile/obsolete'
require 'daitss/proc/datafile/transform'

module Daitss

  class Wip

    def preserve
      # extract the fileGrp section in the sip descriptor, this would be used to determine
      # if the sip descriptor provides the checksum for each file
      sip_descriptor_doc = XML::Document.string metadata['sip-descriptor']
      @file_group = sip_descriptor_doc.find_first %Q{//M:fileSec/M:fileGrp}, NS_PREFIX
      # describe and preserve original_files
      original_datafiles.each do |df|
        begin
          step("describe-migrate-normalize-#{df.id}") do
            df.describe!
            df.migrate!
            df.normalize!
          end
        rescue => e
          raise "error while processing #{df.id}(#{df['aip-path']}): " + e.message
        rescue Interrupt # if the process was interruptted by user stopping the process
          exit 1
        end
      end

      # describe transformed files
      tfs = (migrated_datafiles + normalized_datafiles).reject { |df| df.obsolete? }
      tfs.each do |df| 
        begin
          step("describe-#{df.id}") { df.describe! } 
        rescue => e
          raise "error while describing #{df.id}(#{df['aip-path']}): " + e.message
        end
      end

      # xmlresolve this wip
      step('xml-resolution') do
        xmlres = XmlRes.new
        xmlres.put_collection id

        all_datafiles.select(&:xmlresolution).each do |df|
          event, agent = xmlres.resolve_file df
          df['xml-resolution-event'] = event
          df['xml-resolution-agent'] = agent
        end

        xmlres.save_tarball xmlres_file
        xmlres.remove_collection id
      end

    end

    def original_representation
      original_datafiles
    end

    def current_representation
      original_datafiles.map { |odf| odf.migrated_version || odf }
    end

    def normalized_representation

      if original_datafiles.any? { |odf| odf.normalized_version }
        original_datafiles.map { |odf| odf.normalized_version || odf }
      else
        []
      end

    end

    def represented_datafiles
      (original_representation + current_representation + normalized_representation).uniq
    end

  end

end
