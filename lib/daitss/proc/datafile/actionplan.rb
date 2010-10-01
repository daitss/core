require 'net/http'
require 'daitss/archive'
require 'daitss/proc/datafile'

module Daitss

  class DataFile

    include Daitss

    def migration
      body = ask_actionplan "#{Archive.instance.actionplan_url}/migration"
      JSON.parse body if body
    end

    def normalization
      body = ask_actionplan "#{Archive.instance.actionplan_url}/normalization"
      JSON.parse body if body
    end

    def xmlresolution
      ask_actionplan "#{Archive.instance.actionplan_url}/xmlresolution"
    end

    private

    def ask_actionplan url
      url = URI.parse(url)
      req = Net::HTTP::Post.new url.path
      req.set_form_data 'description' => metadata['describe-file-object']

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
