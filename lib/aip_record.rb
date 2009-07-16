require "dm-core"

class AipRecord
  include DataMapper::Resource
  property :name, String, :key => true
  property :xml, Text
  property :needs_work, Boolean
end

# An in-memory Sqlite3 connection:
DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate!