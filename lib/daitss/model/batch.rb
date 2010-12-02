require 'data_mapper'

require 'daitss/archive'
require 'daitss/model/package'

module Daitss

  class Batch
    include DataMapper::Resource
    property :id, String, :key => true
    has n, :packages
  end

end
