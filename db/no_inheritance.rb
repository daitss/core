require 'rubygems'
require 'dm-core'
require 'dm-types'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, 'mysql://root@localhost/daitss2')

class Datafile 
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :size, Integer, :length => (0..20),  :nullable => false 
  property :format_name, String, :nullable => false # format name, ex: "TIFF"
  property :format_version, String # version, ex: "5.0"
  property :format_registry, String # ex. format registry namespace + formatid, 
    # ex: "http://www.nationalarchives.gov.uk/pronom/fmt/10"
  
  property :create_date, DateTime, :nullable => false
  property :origin, Enum[:archive, :depositor, :unknown], :default => :unknown, :nullable => false
  property :original_path, String, :length => (0..255),  :nullable => false 
    # map from package_path + file_title + file_ext
  property :creator_prog, String, :length => (0..255)

  has 0..n, :bitstream # a datafile may contain 0-n bitstream(s)
  has n, :datafile_event_links
  has n, :datafile_events, :through => :datafile_event_links, :mutable => true
end

class Bitstream
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :size, Integer
  property :format_designation_name, String # format name, ex: "TIFF"
  property :format_designation_version, String # version, ex: "5.0"
  property :format_registry, String # ex. pronom_name/formatid 
  # ex: "http://www.nationalarchives.gov.uk/pronom/fmt/10"

  belongs_to :datafile # a bitstream is belong to a datafile
end

class FormatProperty
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :name, String
  property :value, String
  
  belongs_to :datafile
end

class SevereElement
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :name, String  # the name of the severe element
  property :type, Enum[:inhibitor, :anomaly] # severe element type
  
  belongs_to :datafile
end

class Image
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :width, Integer # positive integer, TODO min = 0
    # the width of the image, in pixels.
  property :height, Integer  # positive int, TODO min = 0
    # the height of the image, in pixels.
  property :compressionScheme, Enum[:Uncompressed, :CCITT_Group_4, :LZW, :JPEG_BasedlineSequential, 
    :JPEG_2000_Lossy, :JPEG_2000_Lossless, :JBIG2, :Deflate_zlib]
    # compression scheme used to store the image data
  property :colorSpace, Enum[:WhiteIsZero, :BlackIsZero, :RGB, :PaletteColor, :TransparencyMask, 
    :CMYK, :YCbCr, :CIELab, :ICCLab, :DeviceGray, :DeviceRGB, :DeviceCMYK, :CalGray, :CalRGB, :Lab,
    :ICCBased, :Separation, :sRGB, :e_sRGB, :sYCC, :Indexed, :Pattern, :DeviceN, :YCCK]
    # the color model of the decompressed image
  property :orientation, Enum[:normal, :flipped, :rotated_180, :flipped_rotated_180, :flipped_rotated_cw_90,
    :rotated_ccw_90, :flipped_rotated_ccw_90, :rotated_cw_90, :unknown], :default => :unknown
    # orientation of the image, with respect to the placement of its width and height.
  property :sample_frequency_unit, Enum[:no_absolute_unit_of_measurement, :in, :centimeter]
    # the unit of measurement for x and y sampling frequency
  property :x_sampling_frequency, Float
    # the number of pixels per sampling frequency unit in the image width
  property :y_sampling_frequency, Float
    # the number of pixels per sampling frequency unit in the image height
  property :bits_per_sample, String # use value "1", "4", "8", "8 8 8", "8 2 2", "16 16 16", "8 8 8 8"] 
    # the number of bits per component for each pixel
  property :samples_per_pixel, Integer # positive int, TODO min = 0
    # the number of color components per pixel
  property :extra_samples, Enum[:unspecified_data, :associated_alpha_data, :unassociated_alpha_data, :range_data]
    # specifies that each pixel has M extra components whose interpretation is defined as above
    
  belongs_to :datafile, :index => true # Image may be associated with a Datafile, 
     # null if the image is associated with a bitstream
  belongs_to :bitstream, :index => true # Image may be associated with a bitstream, 
     # null if the image is associated with a datafile
  # TODO: need to make sure either dfid or bsid is not null.
end

class Audio
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :encoding, String
    # the audio encoding scheme
  property :sampling_frequency, Float
    # the number of audio samples that are recorded per second (in Hertz, i.e. cycles per second)
  property :bit_depth, Integer # TODO positive int
    # the number of bits used each second to represent the audio signal
  property :channels, Integer # TODO positive int
    # the number of channels that are part of the audio stream
  property :duration, Integer
    # the length of the audio recording, described in seconds
  property :channel_map, String
    # channel mapping, mono, stereo, etc, TBD
    
  belongs_to :datafile, :index => true  # Audio may be associated with a Datafile, 
    # null if the audio is associated with a bitstream
  belongs_to :bitstream, :index => true  # Audio may be associated with a bitstream, 
    # null if the audio is associated with a datafile
  # TODO: need to make sure either dfid or bsid is not null.
end

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
end

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
  belongs_to :datafile, :index => true  # Text may be associated with a Datafile, 
      # null if the document is associated with a bitstream
  belongs_to :bitstream, :index => true  # Text may be associated with a bitstream, 
      # null if the document is associated with a datafile
  # TODO: need to make sure either dfid or bsid is not null.
end

class Font
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :fontname, String 
    # the name of the font
  property :embedded, Boolean 
    # where  or not the font is embedded in the document
  
  belongs_to :document
end

class Intentity 
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :original_name, String
  property :entity_id, String
  property :volumn, String
  property :issue, String
  property :title, Text
  
  has 0..n, :intentity_events
  has 1..n, :representations
end

class Representation
  include DataMapper::Resource  
  property :id, String, :key => true, :length => 16
  property :name, String
  property :namespace, Enum[:local]

  belongs_to :intentity
    # representation is part of an int entity
  has 1..n, :datafiles
  has 0..n, :representation_events
end

class Agent
  include DataMapper::Resource
  property :id, String, :key => true
  property :name, String
  property :type, String
  
  has 0..n, :intentity_events # an agent can create 0-n int entity events.
  has 0..n, :representation_events # an agent can create 0-n  representation events.
  has 0..n, :datafile_events # an agent can create 0-n datafile events.
end

class IntentityEvent
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :type, Enum[:submit, :validate, :ingest, :disseminate, :withdraw, :fixitycheck]
  property :datetime, DateTime
  property :outcome, String
  property :details, String  
  
  belongs_to :agent
   # an event must be associated with an agent
   
  belongs_to :intentity

end

class RepresentationEvent
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :type, String # TODO: 
  property :datetime, DateTime
  property :outcome, String
  property :details, String  
  
  belongs_to :agent
    # an event must be associated with an agent
  belongs_to :representation

end

class DatafileEventLink
  include DataMapper::Resource
  property :id, Serial

  belongs_to :datafile_event
  belongs_to :datafile
end

class DatafileEvent
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :type, Enum[:describe, :actionPlan, :migrate, :normalize] # or use transform?
  property :datetime, DateTime
  property :outcome, String
  property :details, String  
  
  belongs_to :agents 
   # an event must be associated with an agent
   
  has n, :datafile_event_links
  has n, :datafiles, :through => :datafile_event_links, :mutable => true

end
# 
# class Relationship
#   include DataMapper::Resource
#   property :df
# end

DataMapper::auto_migrate!