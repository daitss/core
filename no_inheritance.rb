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
  property :name, String
  property :type, Enum[:inhibitor, :anomaly]
  
  belongs_to :datafile
end

class Image
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :width, Integer # positive integer, TODO min = 0
  property :height, Integer  # positive int, TODO min = 0
  property :compressionScheme, Enum[:Uncompressed, :CCITT_Group_4, :LZW, :JPEG_BasedlineSequential, 
    :JPEG_2000_Lossy, :JPEG_2000_Lossless, :JBIG2, :Deflate_zlib]
  property :colorspace, Enum[:WhiteIsZero, :BlackIsZero, :RGB, :PaletteColor, :TransparencyMask, 
    :CMYK, :YCbCr, :CIELab, :ICCLab, :DeviceGray, :DeviceRGB, :DeviceCMYK, :CalGray, :CalRGB, :Lab,
    :ICCBased, :Separation, :sRGB, :e_sRGB, :sYCC, :Indexed, :Pattern, :DeviceN, :YCCK]
  property :orientation, Enum[:normal, :flipped, :rotated_180, :flipped_rotated_180, :flipped_rotated_cw_90,
    :rotated_ccw_90, :flipped_rotated_ccw_90, :rotated_cw_90, :unknown], :default => :unknown
  property :sample_frequency_unit, Enum[:no_absolute_unit_of_measurement, :in, :centimeter]
  property :x_sampling_frequency, Float
  property :y_sampling_frequency, Float
  property :bits_per_sample, Integer # positive int, TODO min = 0
  property :samples_per_pixel, Integer # positive int, TODO min = 0
  property :extra_samples, String
  
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
  property :sampling_frequency, Float
  property :bit_depth, Integer # TODO positive int
  property :channels, Integer # TODO positive int
  property :duration, Integer
  property :channel_map, String
  
  belongs_to :datafile # Audio may be associated with a Datafile, 
    # null if the audio is associated with a bitstream
  belongs_to :bitstream # Audio may be associated with a bitstream, 
    # null if the audio is associated with a datafile
  # TODO: need to make sure either dfid or bsid is not null.
end

class Text
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :dfid, String, :key => true, :length => 16
  property :bsid, String, :key => true, :length => 16
  property :charset, String
  property :byte_order, Enum[:little, :big, :middle, :unknown]
  property :byte_size, Integer
  property :linebreak, Enum[:CR, :CRLF, :LF]
  property :language, String
  property :markup_basic, String
  property :markup_language, String
  property :processingNote, String
  property :pageOrder, Enum[:left_to_right, :right_to_left]
  property :pageSequence, Enum[:reading_order, :inverse_reading_order]
  property :lineOrientation, Enum[:vertical, :horizontal]
  
  belongs_to :datafile # Text may be associated with a Datafile, 
    # null if the text is associated with a bitstream
  belongs_to :bitstream # Text may be associated with a bitstream, 
    # null if the text is associated with a datafile
  # TODO: need to make sure either dfid or bsid is not null.
end

class Document
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :dfid, String, :key => true, :length => 16
  property :bsid, String, :key => true, :length => 16
  property :pageCount, Integer
  property :wordCount, Integer
  property :characterCount, Integer
  property :paragraphCount, Integer
  property :lineCount, Integer
  property :tableCount, Integer
  property :graphicsCount, Integer
  property :language, String
  property :features, Flag[:isTagged, :hasOutline, :hasThumbnails, :hasLayers, :hasForms, 
    :hasAnnotations, :hasAttachments, :useTransparency]
  
  has 0..n, :fonts # A document can contain 0-n fonts
  belongs_to :datafile # Text may be associated with a Datafile, 
      # null if the document is associated with a bitstream
  belongs_to :bitstream # Text may be associated with a bitstream, 
      # null if the document is associated with a datafile
  # TODO: need to make sure either dfid or bsid is not null.
end

class Font
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :fontname, String
  property :embedded, Boolean
  
  belongs_to :document
end

class Intentity 
  include DataMapper::Resource
  property :id, String, :key => true
  property :original_name, String
  property :entity_id, String
  property :volumn, String
  property :issue, String
  property :title, Text
  
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
end

class Event
  include DataMapper::Resource
  property :id, String
  property :type, String
  property :datetime, DateTime
  property :outcome, String
  property :detail, String  
  
  belongs_to :agents 
   # an event must be associated with an agent
end

class Agent
  include DataMapper::Resource
  property :id, String
  property :name, String
  property :type, String
  
  has 0..n, :events # an agent can create 0-n events.
end

DataMapper::auto_migrate!