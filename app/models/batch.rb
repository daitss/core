class Batch
  include DataMapper::Resource
  property :id, String, :key => true
  has n, :packages
end
