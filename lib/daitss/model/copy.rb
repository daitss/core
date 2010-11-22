require 'data_mapper'

require 'daitss/archive'
require 'daitss/model/aip'

# tarball serialization of an AIP
module Daitss

  class Copy

    MAX_SIZE = 2**32-1

    include DataMapper::Resource
    property :id, Serial
    property :url, URI, :required => true # uncomment after all d1 packages are migrated, , :writer => :private #, :default => proc { self.make_url }
    property :sha1, String, :length => 40, :format => %r([a-f0-9]{40}) # uncomment after all d1 packages are migrated, :required => true
    property :md5, String, :length => 40, :format => %r([a-f0-9]{32}), :required => true
    property :size, Integer, :min => 1, :max => MAX_SIZE # uncomment after all d1 packages are migrated,:required => true
    property :revision, Integer, :default => 0, :required => true

    belongs_to :aip

    # skip validation for daitss 1 package not yet migrated
    validates_with_method :size, :check_size,  :if => lambda { |t| t.size}
    validates_with_method :md5, :check_md5, :if => lambda { |t| t.size}

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
        http.read_timeout = archive.http_timeout
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

    def put_to_silo wip
      self.size = wip.tarball_size
      self.md5 = wip.tarball_md5.hexdigest
      self.sha1 = wip.tarball_sha1.hexdigest
      self.url = make_url

      req = Net::HTTP::Put.new self.url.path
      req.content_type = 'application/tar'
      req.content_length = self.size
      req['content-md5'] = self.md5
      req.body_stream = File.open wip.tarball_file

      res = Net::HTTP.start(self.url.host, self.url.port) do |http|
        http.read_timeout = Daitss.archive.http_timeout
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
      "#{archive.storage_url}/#{self.aip.package.id}-#{rev || self.revision}"
    end

  end

end
