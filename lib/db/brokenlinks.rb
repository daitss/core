# LINK_SEPARATER "|"

class BrokenLink
  include DataMapper::Resource
  
  property :datafile_id, String,  :key => true, :length => 100
  property :broken_links, Text
  # a "|" separated list of all broken links in the datafile

  belongs_to :datafile # the associated Datafile

  def fromPremis(df, premis)
    nodes = detailsExtension.find("premis:broken_link", NAMESPACES)
    links = Array.new
    nodes.each do |obj|
      links << obj.content
    end
    attribute_set(:broken_links, links.join("|"))
    df.broken_links << self
  end
  
end
