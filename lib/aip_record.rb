require "dm-core"

class AipRecord
  include DataMapper::Resource
  property :name, String, :key => true
  property :xml, Text
  property :needs_work, Boolean
end
