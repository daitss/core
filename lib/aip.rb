require "dm-core"

require 'libxml'
require 'schematron'

include LibXML

# authoritative aip record
class Aip

  include DataMapper::Resource
  property :name, String, :key => true
  property :xml, Text, :nullable => false
  property :url, String, :nullable => false
  property :sha1, String, :length => 40, :format => %r([a-f0-9]{40}), :nullable => false
  property :size, Integer, :min => 1, :nullable => false
  property :needs_work, Boolean, :nullable => false
  
  validates_with_block do
    doc = XML::Document.string xml

    # validate against schematron
    results = Aip::SCHEMATRON.validate doc

    unless results.empty?
      [false, "descriptor fails daitss aip schematron validation (#{results.size} errors)"]
    else
      true
    end

    # make sure its stored properly
    u = URI.parse url
    req = Net::HTTP::Head.new u.path
    res = Net::HTTP.start(u.host, copy_url.port) { |http| http.request(req) }

    case res
    when Net::HTTPSuccess
    when HTTPNotFound
      [false, "aip is not stored: #{res.code} #{res.msg}: #{res.body}"]
    else
      raise "cannot query aip copy: #{res.code} #{res.msg}: #{res.body}"
    end

    [false, "fixity is wrong: #{sha1} (record) != #{res['Content-SHA1']} (silo)"] unless res['Content-SHA1'] == sha1
    [false, "size is wrong: #{size} (record) != #{res['Content-Length']} (silo)"] unless res['Content-Length'] == size
  end

  def tarball= t
    size = t.size
    sha1 = Digest::SHA1.hexdigest t

    u = URI.parse url
    req = Net::HTTP::Put.new u.path
    req.body = t
    res = Net::HTTP.start(u.host, copy_url.port) { |http| http.request(req) }

    case res
    when Net::HTTPSuccess
    else
      raise "cannot store aip: #{res.code} #{res.msg}: #{res.body}"
    end

  end

end
