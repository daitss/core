require 'dm-core'

class SubmittedSip
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :package_name, String, :key => true
  property :package_size, Integer
  property :number_of_datafiles, Integer
  property :ieid, String
end
