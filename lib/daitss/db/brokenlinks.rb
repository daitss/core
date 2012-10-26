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
            # <eventOutcomeDetailExtension>  looks like:
	    #  <eventOutcomeDetailExtension>
	    #   <broken_link type="stylesheet">http://schema.fcla.edu/xml/broken-stylesheet-student_html.xsl</broken_link>
	    #  </eventOutcomeDetailExtension>
      attribute_set(:broken_links, premis.content)
      attribute_set(:type, premis['type'])
      df.broken_links << self
    end

    after :save do
      puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
    end
  end
end
