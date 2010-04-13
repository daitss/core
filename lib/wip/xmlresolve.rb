require 'wip'
require 'datafile/actionplan'

class Wip

  XML_RES_TARBALL = 'xmlres.tar'

  def xmlresolve!
    url = put_collection_resource
    url.path = url.path + '/'
    resolve_datafiles url
    tar = get_tarball url

    metadata['xml-resolution-tarball'] = tar
    metadata['xml-resolution-event'] = event(:id => "#{uri}/event/xmlresolution",
                                             :type => 'xml resolution',
                                             :outcome => 'success',
                                             :linking_objects => [ uri ],
                                             :linking_agents => [ Daitss::CONFIG['xmlresolution-url'] ])


    metadata['xml-resolution-agent'] = agent(:id => Daitss::CONFIG['xmlresolution-url'],
                                             :name => 'daitss xmlresolution service',
                                             :type => 'software')

  end

  def put_collection_resource
    url = URI.parse "#{Daitss::CONFIG['xmlresolution-url']}/ieids/#{id}"
    req = Net::HTTP::Put.new url.path

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request req
    end

    res.error unless Net::HTTPSuccess === res

    url
  end

  def resolve_datafiles url
    dfs = all_datafiles.select { |df| df.xmlresolution }

    dfs.each do |df|
      %x{curl -s -F xmlfile=@#{df.datapath} #{url}}
    end

  end

  def get_tarball url
    req = Net::HTTP::Get.new url.path

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request req
    end
    res.error unless Net::HTTPSuccess === res
    res.body
  end

end
