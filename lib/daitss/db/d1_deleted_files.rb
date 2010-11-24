require 'data_mapper'

module Daitss

  class D1DeletedFile
    include DataMapper::Resource
    property :id, Serial, :key => true
    property :ieid, String, :index => true, :length => 50 # daitss1 ieid
    property :source, String, :length => 100 #  the file which would be used to restore the duplicate.
    property :duplicate, String, :length => 100 # the duplicate file which was deleted in d1.
  end
end