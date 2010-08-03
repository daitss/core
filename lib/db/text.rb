# define arrays used for validating controlled vocabularies as defined in the textmd
Linebreaks = ["CR", "CR/LF", "LF"]
Text_Byte_Order = ["little", "big", "middle", "Unknown"]
Markup_Basic = ["SGML", "XML", "GML"]
Page_Order = ["left to right", "right to left"]
Line_Layout = ["right-to-left", "left-to-right", "top-to-bottom", "bottom-to-top"]
Line_Orientation = ["vertical", "horizontal"]

class Text
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :charset, String
    # character set employed by the text, see http://www.iana.org/assignments/character-sets
  property :byte_order, String, :length => 32, :required => true, :default => "Unknown"
    # byte order
  property :byte_size, Integer
    # the size of individual byte whtin the bits.
  property :linebreak, String, :length => 16
    # how linebreaks are represented in the text
  property :language, String, :length => 128
    # language used in the text, use Use ISO 639-2 codes.
  property :markup_basis, String, :length => 10
    # The metalanguage used to create the markup language
  property :markup_language, String, :length => 255
    # Markup language employed on the text (i.e., the specific schema or dtd).
  property :processing_note, String, :length => 255
    # Any general note about the processing of the file
  property :page_order,  String, :length => 32
    # The natural page turning order of the text
  property :line_layout, String, :length => 32
    # The arrangement of the page-level divs in the METS file.
  property :line_orientation, String, :length => 32
    # The orientation of the lines on the page

  property :datafile_id, String, :length => 100
  property :bitstream_id, String, :length => 100
  # belongs_to :datafile, :index => true  # Text may be associated with a Datafile,
    # null if the text is associated with a bitstream
  # belongs_to :bitstream, :index => true  # Text may be associated with a bitstream,
    # null if the text is associated with a datafile

  def fromPremis premis
    attribute_set(:charset, premis.find_first("txt:character_info/txt:charset", NAMESPACES).content)
    byte_order = premis.find_first("txt:character_info/txt:byte_order", NAMESPACES)
    attribute_set(:byte_order, byte_order.content) if byte_order
   	byte_size = premis.find_first("txt:character_info/txt:byte_size", NAMESPACES)
 	attribute_set(:byte_size, byte_size.content) if byte_order
    linebreak = premis.find_first("txt:character_info/txt:linebreak", NAMESPACES).content
    attribute_set(:linebreak, linebreak)
	language = premis.find_first("txt:language", NAMESPACES)
	attribute_set(:language, language.content) if language
	markup_basis = premis.find_first("txt:language/txt:markup_basis", NAMESPACES)
    attribute_set(:markup_basis, markup_basis.content) if markup_basis
	markup_language = premis.find_first("txt:language/txt:markup_language", NAMESPACES)
    attribute_set(:markup_language, markup_language.content) if markup_language
	processing_note = premis.find_first("txt:language/txt:processingNote", NAMESPACES)
    attribute_set(:processing_note, processing_note.content) if processing_note
    # following are textmd 3.0 alpha elements
	page_order = premis.find_first("txt:pageOrder", NAMESPACES)
	attribute_set(:page_order, page_order.content) if page_order
	line_layout = premis.find_first("txt:lineLayout", NAMESPACES)
	attribute_set(:line_layout, line_layout.content) if line_layout
	line_orientation = premis.find_first("txt:lineOrientation", NAMESPACES)
	attribute_set(:line_orientation, line_orientation.content) if line_orientation
  end

  before :save do
    # make sure either dfid or bsid is not null.
    if (:datafile_id.nil? && :bitstream_id.nil?)
      raise "this text talbe is neither associates with a datafile nor associates with a bitstream"
    end
  end

  after :save do
    puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
  end

end
