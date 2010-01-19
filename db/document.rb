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
  property :language, String # the natural language used in the document (language code)
  property :features, Flag[:isTagged, :hasOutline, :hasThumbnails, :hasLayers, :hasForms, 
    :hasAnnotations, :hasAttachments, :useTransparency]
    # additional document features.
    
  has 0..n, :fonts # A document can contain 0-n fonts
  belongs_to :datafile, :index => true
    # Document may be associated with a Datafile, null if the document is associated with a bitstream
  belongs_to :bitstream, :index => true
    # Document may be associated with a bitstream, null if the document is associated with a datafile
    # TODO: need to make sure either dfid or bsid is not null.
  
  def fromPremis premis
    attribute_set(:pageCount, premis.find_first("doc:PageCount", NAMESPACES).content.to_i)
    # attribute_set(:wordCount, premis.find_first("doc:wordCount", NAMESPACES).content)
    # attribute_set(:characterCount, premis.find_first("doc:characterCount", NAMESPACES).content)
    # attribute_set(:lineCount, premis.find_first("doc:lineCount", NAMESPACES).content)  
    # attribute_set(:tableCount, premis.find_first("doc:tableCount", NAMESPACES).content)  
    # attribute_set(:graphicsCount, premis.find_first("doc:graphicsCount", NAMESPACES).content)  
    # attribute_set(:language, premis.find_first("doc:document/doc:language", NAMESPACES).content)  

    nodes = premis.find("doc:Features", NAMESPACES)
    nodes.each do |node|
      #TODO
    end
    
    nodes = premis.find("doc:Font", NAMESPACES)
    nodes.each do |node|
      font = Font.new
      font.fromPremis node
      fonts << font
    end
    puts fonts.inspect
    
  end
  
end

class Font
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :fontname, String 
    # the name of the font
  property :embedded, Boolean 
    # where  or not the font is embedded in the document
  
  belongs_to :document, :index => true 
  
  def fromPremis premis
    attribute_set(:fontname, premis.find_first("@FontName", NAMESPACES).value)
    attribute_set(:embedded, premis.find_first("@isEmbedded", NAMESPACES).value) 
  end
  
end