require 'rubygems'
require 'dm-core'
require 'dm-types'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, 'mysql://root@localhost/daitss2')

class PObject
  include DataMapper::Resource
  property :id, String, :key => true
  property :size, Integer
  property :format_designation_name, String # format name, ex: "TIFF"
  property :format_designation_version, String # version, ex: "5.0"
  property :format_registry, String # ex. pronom_name/formatid, 
    # ex: "http://www.nationalarchives.gov.uk/pronom/fmt/10"
  property :type, Discriminator
end

class Datafile < PObject; end

class Bitstream < PObject; end

class FileInfo
  include DataMapper::Resource
   property :create_date, DateTime
   property :origin, Enum[:archive, :depositor, :unknown], :default => :unknown
   property :original_path, String # map from package_path + file_title + file_ext
   property :creator_prog, String

   belongs_to :p_object
   has n, :bitstreams
end

class Intentity 
  include DataMapper::Resource
  property :id, String, :key => true
  property :original_name, String
  property :entity_id, String
  property :volumn, String
  property :issue, String
  property :title, Text
  
  has n, :representations
end

class Representation
  include DataMapper::Resource  
  property :name, String
  property :namespace, Enum[:local]
  
  belongs_to :intentity
  has n, :datafiles
end

class FormatProperty
  include DataMapper::Resource
  property :name, String
  property :value, String
  
  belongs_to :datafile
end

class SevereElement
  include DataMapper::Resource
  property :name, String
  property :type, Enum[:inhibitor, :anomaly]
  
  belongs_to :datafile
end



class Image
  include DataMapper::Resource
  property :width, Integer
  property :height, Integer
  property :compressionScheme, Enum[:Uncompressed, :CCITT_Group_4, :LZW, :JPEG_BasedlineSequential, 
    :JPEG_2000_Lossy, :JPEG_2000_Lossless, :JBIG2, :Deflate_zlib]
  property :colorspace, Enum[:WhiteIsZero, :BlackIsZero, :RGB, :PaletteColor, :TransparencyMask, 
    :CMYK, :YCbCr, :CIELab, :ICCLab, :DeviceGray, :DeviceRGB, :DeviceCMYK, :CalGray, :CalRGB, :Lab,
    :ICCBased, :Separation, :sRGB, :e_sRGB, :sYCC, :Indexed, :Pattern, :DeviceN, :YCCK]
  property :orientation, Enum[:normal, :flipped, :rotated_180, :flipped_rotated_180, :flipped_rotated_cw_90,
    :rotated_ccw_90, :flipped_rotated_ccw_90, :rotated_cw_90, :unknown], :default => :unknown
  property :sample_frequency_unit, Enum[:no_absolute_unit_of_measurement, :in, :centimeter]
  property :x_sampling_frequency, Integer
  property :y_sample_frequency, Integer
  property :bits_per_sample, Integer
  property :samples_per_pixel, Integer
  property :extra_samples, Integer
  
  belongs_to :p_object
end

class Audio
  include DataMapper::Resource
  property :sampling_frequency, Integer
  property :bit_depth, Integer
  property :channels, Integer
  property :duration, Integer
  property :channel_map, String
  
  belongs_to :p_object
end

class Text
  include DataMapper::Resource
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
  
  belongs_to :p_object
end

class Document
  include DataMapper::Resource
  property :pageCount, Integer
  property :wordCount, Integer
  property :characterCount, Integer
  property :paragraphCount, Integer
  property :lineCount, Integer
  property :tableCount, Integer
  property :graphicsCount, Integer
  property :language, String
  property :features, Flag[:isTagged, :hasOutline, :hasThumbnails, :hasLayers, 
    :hasForms, :hasAnnotations, :hasAttachments, :useTransparency]
  
  belongs_to :p_object    
end

class Font
  include DataMapper::Resource
  property :fontname, String
  property :embedded, Boolean
  
  belongs_to :document
end

class Event
  include DataMapper::Resource
  property :id, String
  property :type, String
  property :datetime, DateTime
  property :outcome, String
  property :detail, String  
end

class Agent
  include DataMapper::Resource
  property :id, String
  property :name, String
  property :type, String
end

DataMapper::auto_migrate!