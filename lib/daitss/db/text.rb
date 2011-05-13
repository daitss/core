module Daitss

  # define arrays used for validating controlled vocabularies as defined in the textmd
  Linebreaks = ["CR", "CR/LF", "LF"]
  Text_Byte_Order = ["little", "big", "middle", "Unknown"]
  Markup_Basis = ["SGML", "XML", "GML"]
  Page_Order = ["left to right", "right to left"]
  Line_Layout = ["right-to-left", "left-to-right", "top-to-bottom", "bottom-to-top"]
  Line_Orientation = ["vertical", "horizontal"]

  class Text
    include DataMapper::Resource
    property :id, Serial, :key => true
    property :charset, String
    # character set employed by the text, see http://www.iana.org/assignments/character-sets
    property :byte_order, String, :length => 32, :required => true, :default => "Unknown"
    # validates_with_method :byte_order,:method => :validate_byteorder
    # byte order
    property :byte_size, Integer
    # the size of individual byte whtin the bits.
    property :linebreak, String, :length => 16
    # validates_with_method :linebreak, :method => :validate_linebreak
    # how linebreaks are represented in the text
    property :language, String, :length => 128
    # language used in the text, use Use ISO 639-2 codes.
    property :markup_basis, String, :length => 10
    # validates_with_method :markup_basis, :method => :validate_markup_basis
    # The metalanguage used to create the markup language
    property :markup_language, String, :length => 255
    # Markup language employed on the text (i.e., the specific schema or dtd).
    property :processing_note, String, :length => 255
    # Any general note about the processing of the file
    property :page_order,  String, :length => 32
    # validates_with_method :page_order, :method => :validate_page_order
    # The natural page turning order of the text
    property :line_layout, String, :length => 32
    # validates_with_method :line_layout, :method => :validate_line_layout
    # The arrangement of the page-level divs in the METS file.
    property :line_orientation, String, :length => 32
    #validates_with_method :line_orientation, :method => :validate_line_orientation
    # The orientation of the lines on the page

    property :datafile_id, String, :length => 100
    property :bitstream_id, String, :length => 100

    def fromPremis premis
      attribute_set(:charset, premis.find_first("txt:character_info/txt:charset", NAMESPACES).content)
      byte_order = premis.find_first("txt:character_info/txt:byte_order", NAMESPACES)
      if byte_order
        attribute_set(:byte_order, byte_order.content) 
        validate_byteorder
      end
      byte_size = premis.find_first("txt:character_info/txt:byte_size", NAMESPACES)
      attribute_set(:byte_size, byte_size.content) if byte_size
      linebreak = premis.find_first("txt:character_info/txt:linebreak", NAMESPACES)
      if linebreak && !linebreak.content.empty?
        attribute_set(:linebreak, linebreak.content)
        validate_linebreak
      end
      language = premis.find_first("txt:language", NAMESPACES)
      attribute_set(:language, language.content) if language
      markup_basis = premis.find_first("txt:language/txt:markup_basis", NAMESPACES)
      if markup_basis
        attribute_set(:markup_basis, markup_basis.content)
        validate_markup_basis
      end
      markup_language = premis.find_first("txt:language/txt:markup_language", NAMESPACES)
      attribute_set(:markup_language, markup_language.content) if markup_language
      processing_note = premis.find_first("txt:language/txt:processingNote", NAMESPACES)
      attribute_set(:processing_note, processing_note.content) if processing_note
      # following are textmd 3.0 alpha elements
      page_order = premis.find_first("txt:pageOrder", NAMESPACES)
      if page_order
       attribute_set(:page_order, page_order.content) 
        validate_page_order
      end
      line_layout = premis.find_first("txt:lineLayout", NAMESPACES)
      if line_layout
        attribute_set(:line_layout, line_layout.content) 
        validate_line_layout
      end
      line_orientation = premis.find_first("txt:lineOrientation", NAMESPACES)
      if line_orientation
        attribute_set(:line_orientation, line_orientation.content)
        validate_line_orientation
      end
    end

    def validate_linebreak
      unless @linebreak.nil? || Linebreaks.include?(@linebreak)
        raise "value #{@linebreak} is not a valid linebreak value"
      end
    end

    def validate_byteorder
      unless Text_Byte_Order.include?(@byte_order)
        raise "value #{@byte_order} is not a valid text byte order"
      end
    end

    def validate_markup_basis
      unless @markup_basis.nil? || Markup_Basis.include?(@markup_basis)
        raise "value #{@markup_basis} is not a valid markup_basis value" 
      end
    end

    def validate_page_order
      unless @page_order.nil? || Page_Order.include?(@page_order)
        raise "value #{@page_order} is not a valid page_order value" 
      end
    end

    def validate_line_layout
      unless @line_layout.nil? || Line_Layout.include?(@line_layout)
        raise "value #{@line_layout} is not a valid line_layout value"
      end
    end

    def validate_line_orientation
      unless @line_orientation.nil? || Line_Orientation.include?(@line_orientation)
        raise "value #{@line_orientation} is not a valid line_orientation value" 
      end
    end
    
    before :save do
      # make sure either dfid or bsid is not null.
      if (:datafile_id.nil? && :bitstream_id.nil?)
        raise "this text table neither associates with a datafile nor associates with a bitstream"
      end
    end

    after :save do
      puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
    end

  end

end
