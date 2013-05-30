require 'net/http'
require 'json'

require 'daitss/archive'
require 'daitss/proc/datafile'

module Daitss

  class DataFile

    include Daitss

    def migration
      body = ask_actionplan "migration"
      XML::Document.string body if body
    end

    def normalization
      body = ask_actionplan "normalization"
      JSON.parse body if body
    end

    def xmlresolution
      ask_actionplan "xmlresolution"
    end

    private

    def ask_actionplan strategy
      url = URI.parse(archive.actionplan_url + '/' + strategy)
      req = Net::HTTP::Post.new url.path

      form_data = {
        'object' => metadata['describe-file-object'],
        'event-id-type' => 'URL',
        'event-id-value' => "#{uri}/event/#{strategy}/#{next_event_index strategy}"
      }

      req.set_form_data form_data
   
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.read_timeout = Archive.instance.http_timeout
        http.request req
      end

      case res
      when Net::HTTPSuccess then res.body
      when Net::HTTPNotFound then nil
      else res.error!
      end

    end

  end

end
