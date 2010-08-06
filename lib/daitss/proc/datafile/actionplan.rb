require 'net/http'
require 'daitss/config'
require 'datafile'

class DataFile

  include Daitss

  def migration
    ask_actionplan "#{CONFIG['actionplan']}/migration"
  end

  def normalization
    ask_actionplan "#{CONFIG['actionplan']}/normalization"
  end

  def xmlresolution
    ask_actionplan "#{CONFIG['actionplan']}/xmlresolution"
  end

  private

  def ask_actionplan url
    url = URI.parse(url)
    req = Net::HTTP::Post.new url.path
    req.set_form_data 'description' => metadata['describe-file-object']

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request req
    end

    case res
    when Net::HTTPRedirection then res['location']
    when Net::HTTPNotFound then nil
    else res.error!
    end

  end

end
