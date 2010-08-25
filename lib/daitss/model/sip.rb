require 'data_mapper'

# description of a submitted sip
class Sip
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :size_in_bytes, Integer, :min => 0, :max => 2**63-1
  property :number_of_datafiles, Integer, :min => 0, :max => 2**63-1

  belongs_to :package
end
