require 'daitss/proc/wip'
require 'daitss/proc/wip/step'
require 'daitss/proc/wip/preserve'
require 'daitss/proc/wip/from_aip'
require 'daitss/model/aip'
require 'daitss/model/aip/from_wip'
require 'daitss/proc/template/descriptor'
require 'daitss/proc/template/premis'
require 'daitss/proc/metadata'

class Wip

  def disseminate
    raise "no aip for #{id}" unless package.aip

    step('load-aip') do
      load_from_aip
    end

    preserve!

    step('write-disseminate-event') do


      metadata['disseminate-event'] = event(:id => "#{uri}/event/disseminate/#{next_event_index 'disseminate'}",
                                            :type => 'disseminate',
                                            :outcome => 'success',
                                            :linking_objects => [ uri ],
                                            :linking_agents => [ "info:fcla/daitss/disseminate" ])

    end

    step('write-disseminate-agent') do
      metadata['disseminate-agent'] = agent(:id => "info:fcla/daitss/disseminate",
                                            :name => 'daitss disseminate',
                                            :type => 'software')
    end

    step('make-aip-descriptor') do
      metadata['aip-descriptor'] = descriptor
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
