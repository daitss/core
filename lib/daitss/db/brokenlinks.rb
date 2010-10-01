require 'data_mapper'

module Daitss

  class BrokenLink
    include DataMapper::Resource

    property :id, Serial

    property :broken_links, Text
    # a "|" separated list of all broken links in the datafile

    belongs_to :datafile # the associated Datafile

    def fromPremis(df, premis)
      nodes = premis.find("premis:broken_link", NAMESPACES)
      links = Array.new
      nodes.each do |obj|
        links << obj.content
      end
      attribute_set(:broken_links, links.join("|"))
      df.broken_links << self
    end

    after :save do
      puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
    end
  end

end
