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

      step('load-aip') do
        load_from_aip
      end

      preserve!

      step('write-disseminate-event') do
        metadata['disseminate-event'] = disseminate_event package, next_event_index('disseminate')
      end

      step('write-disseminate-agent') do
        metadata['disseminate-agent'] = system_agent
      end

      step('make-aip-descriptor') do
        metadata['aip-descriptor'] = descriptor
      end

      step('make-tarball') do
        make_tarball
      end

      step('update-aip') do

        Aip.transaction do
          aip = Aip.update_from_wip self
          doc = XML::Document.string(aip.xml)
          aipInPremis = AIPInPremis.new
          aipInPremis.process aip.package, doc
        end

      end

      step('deliver-dip') do
        raise "no drop path specified" unless tags.has_key? 'drop-path'
        aip = Package.get(id).aip or raise "package #{id} not found"
        url = URI.parse aip.copy.url.to_s

        res = Net::HTTP.start(url.host, url.port) do |http|
          http.read_timeout = Archive.instance.http_timeout
          http.get url.path
        end

        res.error! unless Net::HTTPSuccess === res
        open(tags['drop-path'], 'w') { |io| io.write res.body }
        sha1 = open(tags['drop-path']) { |io| Digest::SHA1.hexdigest io.read }

        unless sha1 == aip.copy.sha1
          raise "#{aip.copy.url} sha1 is wrong: expected #{aip.copy.sha1}, actual #{sha1}"
        end

      end

    end

  end

end
