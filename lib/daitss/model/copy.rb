require 'data_mapper'

require 'daitss/archive'
require 'daitss/model/aip'

# tarball serialization of an AIP
class Copy

  MAX_SIZE = 2**32-1

  include DataMapper::Resource
  property :id, Serial
  property :url, URI, :required => true, :writer => :private #, :default => proc { self.make_url }
  property :sha1, String, :length => 40, :format => %r([a-f0-9]{40}), :required => true
  property :md5, String, :length => 40, :format => %r([a-f0-9]{32}), :required => true
  property :size, Integer, :min => 1, :max => MAX_SIZE ,:required => true
  property :revision, Integer, :default => 0, :required => true

  belongs_to :aip

  validates_with_method :size, :check_size
  validates_with_method :md5, :check_md5

  def check_size
    res = head_from_silo

    unless res['Content-Length'].to_i == size
      [false, "copy size is wrong: #{size} (record) != #{res['Content-Length']} (silo)"]
    else
      true
    end

  end

  def check_md5
    res = head_from_silo

    unless res['Content-MD5'] == md5
      [false, "copy fixity is wrong: #{md5} (record) != #{res['Content-MD5']} (silo)"]
    else
      true
    end

  end

  def get_from_silo
    req = Net::HTTP::Get.new self.url.path

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::Archive.instance.http_timeout
      http.request(req)
    end

    res.error! unless Net::HTTPSuccess === res

    unless self.size = res.body.size
      raise "#{url} size is wrong: expected #{size}, actual #{res.body.size}"
    end

    sha1 = Digest::SHA1.hexdigest res.body
    unless self.sha1 = sha1
      raise "#{url} sha1 is wrong: expected #{self.sha1}, actual #{sha1}"
    end

    res.body
  end

  def head_from_silo
    req = Net::HTTP::Head.new self.url.path
    res = Net::HTTP.start(self.url.host, self.url.port) { |http| http.request(req) }
    res.error! unless Net::HTTPSuccess === res
    res
  end

  def put_to_silo aip_archive
    self.size = aip_archive.size
    self.md5 = aip_archive.md5
    self.sha1 = aip_archive.sha1
    self.url = make_url

    req = Net::HTTP::Put.new self.url.path
    req.content_type = 'application/tar'
    req.content_length = aip_archive.size
    req['content-md5'] = aip_archive.md5
    req.body_stream = aip_archive.open

    res = Net::HTTP.start(self.url.host, self.url.port) do |http|
      http.read_timeout = Daitss::Archive.instance.http_timeout
      http.request(req)
    end

    res.error! unless Net::HTTPCreated === res
  end

  def delete_from_silo rev=nil

    url = if rev
            URI.parse make_url(rev)
          else
            self.url
          end

    req = Net::HTTP::Delete.new url.path
    res = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
    res.error! unless Net::HTTPSuccess === res
  end

  private

  def make_url rev=nil
    "#{Daitss::Archive.instance.storage_url}/#{self.aip.package.id}-#{rev || self.revision}"
  end

end
