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

    belongs_to :aip

    def download f
      rs = RandyStore.new id, url.to_s
      rs.download f

      if size

        unless File.size(f) == self.size
          raise "#{url} size is wrong: expected #{size}, actual #{File.size(f)}"
        end

        actual_sha = Digest::SHA1.file(f).hexdigest
        unless actual_sha == self.sha1
          raise "#{url} sha1 is wrong: expected #{self.sha1}, actual #{actual_sha1}"
        end

      end

      actual_md5 = Digest::MD5.file(f).hexdigest
      unless actual_md5 == self.md5
        raise "#{url} md5 is wrong: expected #{self.md5}, actual #{actual_md5}"
      end

      f
    end

  end

end
