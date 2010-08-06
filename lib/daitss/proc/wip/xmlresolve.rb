require 'wip'
require 'datafile/actionplan'

class Wip

  include Daitss

  XML_RES_TARBALL = 'xmlres.tar'

  def xmlresolve!
    url = put_collection_resource
    url.path = url.path + '/'
    resolve_datafiles url
    tar = get_tarball url
    metadata['xml-resolution-tarball'] = tar
  end

  def put_collection_resource
    url = URI.parse "#{CONFIG['xmlresolution']}/ieids/#{id}"
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

    docs = dfs.each do |df|
      o = %x{curl -s -F xmlfile=@#{df.datapath} #{url}}
      doc = XML::Document.string o
      doc.find_first("//P:eventIdentifierValue", NS_PREFIX).content = "#{df.uri}/event/xmlresolution"
      doc.find_first("//P:linkingObjectIdentifierValue", NS_PREFIX).content = df.uri

      d = XML::Document.new
      d.root = d.import(doc.find_first "//P:event", NS_PREFIX)
      df['xml-resolution-event'] = d.root.to_s

      d = XML::Document.new
      d.root = d.import(doc.find_first "//P:agent", NS_PREFIX)
      df['xml-resolution-agent'] = d.root.to_s
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
