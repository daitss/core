Linebreaks = { "CR" => :CR, "CR/LF" => :CRLF, "LF" => :LF }

class Text
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :charset, String 
    # character set employed by the text, see http://www.iana.org/assignments/character-sets
  property :byte_order, Enum[:little, :big, :middle, :unknown] 
    # byte order 
  property :byte_size, Integer 
    # the size of individual byte whtin the bits.
  property :linebreak, Enum[:CR, :CRLF, :LF] 
    # how linebreaks are represented in the text
  property :language, String 
    # language used in the text, use Use ISO 639-2 codes.
  property :markup_basic, Enum[:SGML, :XML, :GML] 
    # The metalanguage used to create the markup language
  property :markup_language, String 
    # Markup language employed on the text (i.e., the specific schema or dtd).
  property :processingNote, String 
    # Any general note about the processing of the file
  property :pageOrder, Enum[:left_to_right, :right_to_left]
    # The natural page turning order of the text
  property :pageSequence, Enum[:reading_order, :inverse_reading_order] 
    # The arrangement of the page-level divs in the METS file.
  property :lineOrientation, Enum[:vertical, :horizontal]
    # The orientation of the lines on the page
  
  belongs_to :datafile, :index => true  # Text may be associated with a Datafile, 
    # null if the text is associated with a bitstream
  belongs_to :bitstream, :index => true  # Text may be associated with a bitstream, 
    # null if the text is associated with a datafile
  # TODO: need to make sure either dfid or bsid is not null.
    
  def fromPremis premis
    attribute_set(:charset, premis.find_first("txt:character_info/txt:charset", NAMESPACES).content)
    # attribute_set(:byte_order, premis.find_first("", NAMESPACES).content)
    # attribute_set(:byte_size, premis.find_first("", NAMESPACES).content)
    linebreak = premis.find_first("txt:character_info/txt:linebreak", NAMESPACES).content   
    attribute_set(:linebreak, Linebreaks[linebreak]) 
    # attribute_set(:language, premis.find_first("", NAMESPACES).content) 
    attribute_set(:markup_basic, premis.find_first("txt:language/txt:markup_basis", NAMESPACES).content)  
    attribute_set(:markup_language, premis.find_first("txt:language/txt:markup_language", NAMESPACES).content) 
    attribute_set(:processingNote, premis.find_first("txt:language/txt:processingNote", NAMESPACES).content) 
    # attribute_set(:pageOrder, premis.find_first("", NAMESPACES).content) 
    # attribute_set(:pageSequence, premis.find_first("", NAMESPACES).content) 
    # attribute_set(:lineOrientation, premis.find_first("", NAMESPACES).content) 
  end
end