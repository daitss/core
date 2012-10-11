require 'data_mapper'

module Daitss

  class BrokenLink
    include DataMapper::Resource

    property :id, Serial

    property :broken_links, Text
    # a "|" separated list of all broken links in the datafile <- this is before the new column "type" was added
    #
    #
    property :type, Text
    # can be one of:   stylesheet, dtd,  schema,  or unresolvable

    belongs_to :datafile # the associated Datafile

    def fromPremis(df, premis)
# pick off the first broken link only
# premis looks like:
	    #  <eventOutcomeDetailExtension>
	    #   <broken_link type="stylesheet">http://schema.fcla.edu/xml/broken-stylesheet-student_html.xsl</broken_link>
	    #   <broken_link type="unresolvable">http://www.w3.org/2001/XMLSchema</broken_link>
	    #   <broken_link type="unresolvable">info:lc/xmlns/premis-v2-beta</broken_link>
	    #  </eventOutcomeDetailExtension>
      nodes = premis.find("premis:broken_link", NAMESPACES)
      links = Array.new
      nodes.each do |obj|
        links << obj.content
	break
      end
      attribute_set(:broken_links, links[0])

      df.broken_links << self
      
      kids  = Array.new
      attrs_of_kids = Array.new
      types = Array.new
      values = Array.new
      premis.children.each {|z| kids   << z}  # kids is a array of nodes
      kids.each {|z| attrs_of_kids  << z.attributes}  # attrs_of_kids is an array of attributes

      attrs_of_kids.each {|z| z.each {|w| types << w}}  # types will become an array each element holds a single attribute
      types.each do 
        |z| values << z.value
        break
      end
      attribute_set(:type, values[0])
    end

    after :save do
      puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
    end
  end

end
