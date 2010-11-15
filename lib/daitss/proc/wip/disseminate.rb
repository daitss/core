require 'daitss/proc/wip'
require 'daitss/proc/wip/journal'
require 'daitss/proc/wip/preserve'
require 'daitss/proc/wip/from_aip'
require 'daitss/model/aip'
require 'daitss/model/aip/from_wip'
require 'daitss/proc/template/descriptor'
require 'daitss/proc/template/premis'
require 'daitss/proc/metadata'

module Daitss

  class Wip

    def disseminate
      raise "no aip for #{id}" unless package.aip

      step 'load-aip'  do
        load_from_aip
      end

      preserve

      step 'write-disseminate-event'  do
        metadata['disseminate-event'] = disseminate_event package, next_event_index('disseminate')
      end

      step 'write-disseminate-agent'  do
        metadata['disseminate-agent'] = system_agent
      end

      step 'make-aip-descriptor'  do
        metadata['aip-descriptor'] = descriptor
      end

      step 'make-tarball'  do
        make_tarball
      end

      step 'update-aip'  do

        Aip.transaction do
          aip = Aip.update_from_wip self
          doc = XML::Document.string(aip.xml)
          aipInPremis = AIPInPremis.new
          aipInPremis.process aip.package, doc
        end

      end

      step 'deliver-dip'  do
        set_drop_path
        FileUtils.cp tarball_file, drop_path
      end

    end

    def drop_path
      @info['drop-path']
    end

    def set_drop_path
      @info['drop-path'] = next_drop_path
      save_info
    end

    def next_drop_path
      pattern = File.join archive.disseminate_path, "#{id}-*.tar"
      dips = Dir[pattern]

      n = if dips.empty?
            0
          else
            dips.map { |f| File.basename(f)[%r{#{id}-(\d+).tar}, 1].to_i }.max + 1
          end

      File.join archive.disseminate_path, "#{id}-#{n}.tar"
    end

  end

end
