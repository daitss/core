require 'net/http'
require 'config'
require 'datafile'

class DataFile

  def migration
    ask_actionplan "#{CONFIG['actionplan-url']}/migration"
  end

  def normalization
    ask_actionplan "#{CONFIG['actionplan-url']}/normalization"
  end

  private

  def ask_actionplan url
    res = Net::HTTP.post_form URI.parse(url), 'description' => metadata['describe-file-object']

    case res
    when Net::HTTPRedirection then res['location']
    when Net::HTTPNotFound then nil
    else res.error!
    end

  end

end
