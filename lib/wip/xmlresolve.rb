require 'wip'

class Wip

  def xmlresolve

    # PUT to new resource
    url = URL.parse "#{Daitss::CONFIG['xmlresolution-url']}/ieids/#{id}"
    req = Net::HTTP::Put.new url.path

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-read-timeout']
      http.request req
    end

    res.error unless Net::HTTPSuccess === res

    datafiles.each do ||
    end

    # ask for the tarball

    metadata['xml-resolution-tarball'] = 0
    metadata['xml-resolution-event'] = 0
    metadata['xml-resolution-agent'] = 0
  end

end
