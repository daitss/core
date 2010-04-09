class BrokenLink
  include DataMapper::Resource
  
  property :datafile_id, String,  :key => true, :length => 100
  property :broken_links, Text
  # a "|" separated list of all missing links in the datafile

  belongs_to :datafile # the associated Datafile

  def fromPremis premis
    # TODO waiting for aip descriptor
  end
  
end
