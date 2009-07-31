require 'dm-core'
require 'dm-types'

#DataMapper.setup(:default, 'sqlite3::memory:')
#DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/test.db")
DataMapper.setup(:default, 'mysql://root@localhost/daitss2')

class Datafile
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :size, Integer, :length => (0..20),  :nullable => false 
  property :format_name, String, :nullable => false # format name, ex: "TIFF"
  property :format_version, String # version, ex: "5.0"
  property :format_registry, String # ex. format registry namespace + formatid, 
  property :create_date, DateTime, :nullable => false
  property :origin, Enum[:archive, :depositor, :unknown], :default => :unknown, :nullable => false
  property :original_path, String, :length => (0..255),  :nullable => false 
  property :creator_prog, String, :length => (0..255)
  
  has 0..n, :bitstreams # a datafile may contain 0-n bitstream(s)
  
  has 0..1, :datafile_image_link
  has 0..1, :image, :through => :datafile_image_link
end

class Bitstream
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :size, Integer
  property :format_designation_name, String # format name, ex: "TIFF"
  property :format_designation_version, String # version, ex: "5.0"
  property :format_registry, String # ex. pronom_name/formatid 
  
  belongs_to :datafile # a bitstream is belong to a datafile
  
  has 0..1, :bitstream_image_link
  has 0..1, :image, :through => :bitstream_image_link
end

# Image is the only example
# Every meta data record will need a link table to datafile and bitstream
class Image
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
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
  
  has 0..1, :datafile_image_link
  has 0..1, :datafile, :through => :datafile_image_link
  
  has 0..1, :bitstream_image_link
  has 0..1, :bitstream, :through => :bitstream_image_link
end

class DatafileImageLink
  include DataMapper::Resource
  property :id,         Serial

  belongs_to :image
  belongs_to :datafile
end

class BitstreamImageLink
  include DataMapper::Resource
  property :id,         Serial

  belongs_to :image
  belongs_to :Bitstream
end

DataMapper::auto_migrate!