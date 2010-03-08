require 'net/http'
require 'daitss/config'
require 'datafile'

class DataFile

  def migration
    ask_actionplan "#{Daitss::CONFIG['actionplan-url']}/migration"
  end

  def normalization
    ask_actionplan "#{Daitss::CONFIG['actionplan-url']}/normalization"
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
