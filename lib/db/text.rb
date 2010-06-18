# define arrays used for validating controlled vocabularies as defined in the textmd
Linebreaks = ["CR", "CR/LF", "LF"]
Byte_Order = ["little", "big", "middle", "unknown"]
Markup_Basic = ["SGML", "XML", "GML"]
Page_Order = ["left to right", "right to left"]
Page_Sequence = ["reading order", "inverse reading order"]
Line_Orientation = ["vertical", "horizontal"]

class Text
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :charset, String
    # character set employed by the text, see http://www.iana.org/assignments/character-sets
  property :byte_order, String, :length => 10, :required => true, :default => "unknown"
    # byte order
  property :byte_size, Integer
    # the size of individual byte whtin the bits.
  property :linebreak, String, :length => 10
    # how linebreaks are represented in the text
  property :language, String
    # language used in the text, use Use ISO 639-2 codes.
  property :markup_basic, String, :length => 10
    # The metalanguage used to create the markup language
  property :markup_language, String
    # Markup language employed on the text (i.e., the specific schema or dtd).
  property :processingNote, String
    # Any general note about the processing of the file
  property :pageOrder,  String, :length => 20, :required => true, :default => "left to right"
    # The natural page turning order of the text
  property :pageSequence, String, :length => 20, :required => true, :default => "reading order"
    # The arrangement of the page-level divs in the METS file.
  property :lineOrientation, String, :length => 20, :required => true, :default => "horizontal"
    # The orientation of the lines on the page

  property :datafile_id, String, :length => 100
  property :bitstream_id, String, :length => 100
  # belongs_to :datafile, :index => true  # Text may be associated with a Datafile,
    # null if the text is associated with a bitstream
  # belongs_to :bitstream, :index => true  # Text may be associated with a bitstream,
    # null if the text is associated with a datafile

  def fromPremis premis
    attribute_set(:charset, premis.find_first("txt:character_info/txt:charset", NAMESPACES).content)
    # attribute_set(:byte_order, premis.find_first("", NAMESPACES).content)
    # attribute_set(:byte_size, premis.find_first("", NAMESPACES).content)
    linebreak = premis.find_first("txt:character_info/txt:linebreak", NAMESPACES).content
    attribute_set(:linebreak, linebreak)
    # attribute_set(:language, premis.find_first("", NAMESPACES).content)
    attribute_set(:markup_basic, premis.find_first("txt:language/txt:markup_basis", NAMESPACES).content)
    attribute_set(:markup_language, premis.find_first("txt:language/txt:markup_language", NAMESPACES).content)
    attribute_set(:processingNote, premis.find_first("txt:language/txt:processingNote", NAMESPACES).content)
    # attribute_set(:pageOrder, premis.find_first("", NAMESPACES).content)
    # attribute_set(:pageSequence, premis.find_first("", NAMESPACES).content)
    # attribute_set(:lineOrientation, premis.find_first("", NAMESPACES).content)
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
