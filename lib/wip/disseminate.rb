require 'wip'
require 'wip/step'
require 'wip/preserve'
require 'wip/load_aip'
require 'db/aip'
require 'db/aip/wip'
require 'descriptor'
require 'template/premis'

class Wip

  def disseminate

    step('load-aip') do
      load_from_aip
    end

    preserve!

    step('write-disseminate-event') do

      metadata['disseminate-event'] = event(:id => "#{uri}/event/disseminate", 
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
      Aip::update_from_wip self
    end

    step('deliver-dip') do
      raise "no drop path specified" unless tags.has_key? 'drop-path'
      aip = Aip.get! id
      url = URI.parse aip.copy_url.to_s
      res = Net::HTTP.start(url.host, url.port) { |http| http.get url.path }
      res.error! unless Net::HTTPSuccess === res
      open(tags['drop-path'], 'w') { |io| io.write res.body }
      sha1 = open(tags['drop-path']) { |io| Digest::SHA1.hexdigest io.read }

      unless sha1 == aip.copy_sha1
        raise "#{aip.copy_url} sha1 is wrong: expected #{aip.copy_sha1}, actual #{sha1}" 
      end

    end

  end

end
