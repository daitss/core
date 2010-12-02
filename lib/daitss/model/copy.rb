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

    def get_from_silo
      rs = RandyStore.new id, url.to_s
      data = rs.get

      if size
      unless data.size == size
        raise "#{url} size is wrong: expected #{size}, actual #{data.size}"
      end
      
      unless Digest::SHA1.hexdigest(data) == sha1
        raise "#{url} sha1 is wrong: expected #{self.sha1}, actual #{sha1}"
      end
      end

      unless Digest::MD5.hexdigest(data) == md5
        raise "#{url} md5 is wrong: expected #{self.md5}, actual #{md5}"
      end


      data
    end

  end

end
