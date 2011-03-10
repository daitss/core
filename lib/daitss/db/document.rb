require 'data_mapper'
require 'dm-validations'

module Daitss

  FEATURES = {
    "hasOutline" => :hasOutline,
    "isTagged" => :isTagged,
    "hasThumbnails" => :hasThumbnails,
    "hasAnnotations" => :hasAnnotations
  }

  class Document
    include DataMapper::Resource
    property :id, Serial, :key => true
    property :pageCount, Integer
    # total number of pages in the document
    property :wordCount, Integer
    # totall number of words in the document
    property :characterCount, Integer # total number of characters in the document
    property :paragraphCount, Integer # total number of paragraphs in the document
    property :lineCount, Integer # total number of lines in the document
    property :tableCount, Integer # total number of tables in the document
    property :graphicsCount, Integer # total number of graphics in the document
    property :language, String, :length => 128 # the natural language used in the document (language code)
    property :features, Flag[:isTagged, :hasOutline, :hasThumbnails, :hasLayers, :hasForms,
      :hasAnnotations, :hasAttachments, :useTransparency]
    # additional document features.

    has 0..n, :fonts, :constraint=>:destroy # A document can contain 0-n fonts
    property :datafile_id, String, :length => 100
    property :bitstream_id, String, :length => 100

    def fromPremis premis
      attribute_set(:pageCount, premis.find_first("doc:PageCount", NAMESPACES).content.to_i)
      # attribute_set(:wordCount, premis.find_first("doc:wordCount", NAMESPACES).content)
      # attribute_set(:characterCount, premis.find_first("doc:characterCount", NAMESPACES).content)
      # attribute_set(:lineCount, premis.find_first("doc:lineCount", NAMESPACES).content)
      # attribute_set(:tableCount, premis.find_first("doc:tableCount", NAMESPACES).content)
      # attribute_set(:graphicsCount, premis.find_first("doc:graphicsCount", NAMESPACES).content)
      lang = premis.find_first("doc:Language", NAMESPACES)
      attribute_set(:language, lang.content) unless lang.nil?

      # set all features associated with this document
      nodes = premis.find("doc:Features", NAMESPACES)
      nodes.each do |node|
        attribute_set(:features, FEATURES[node.content])
      end

      # extract all fonts encoded in the document
      nodes = premis.find("doc:Font", NAMESPACES)
      nodes.each do |node|
        font = Font.new
        font.fromPremis node
        fonts << font
      end
    end

    def check_errors
      fonts.each do |obj| 
        obj.errors.full_messages.join "\n" unless obj.valid?
      end
      raise self.errors.full_messages.join "\n" unless valid?
    end
    
    before :save do
      # make sure either dfid or bsid is not null.
      if (:datafile_id.nil? && :bitstream_id.nil?)
        raise "this document neither associates with a datafile nor associates with a bitstream"
      end
    end

    after :save do
      puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
    end

  end

  class Font
    include DataMapper::Resource
    property :id, Serial, :key => true
    property :fontname, String, :length => 255
    # the name of the font
    property :embedded, Boolean
    # where or not the font is embedded in the document

    belongs_to :document, :index => true

    def fromPremis premis
      attribute_set(:fontname, premis.find_first("@FontName", NAMESPACES).value)
      attribute_set(:embedded, premis.find_first("@isEmbedded", NAMESPACES).value)
    end

  end

end
