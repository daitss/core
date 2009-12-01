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
  
  def setDFID dfid
    attribute_set(:datafile_id, dfid)
  end

  def setBFID bfid
    attribute_set(:bitstream_id, bfid)
  end
    
  def fromPremis premis
    attribute_set(:width, premis.find_first("mix:imageWidth", NAMESPACES).content)
    attribute_set(:height, premis.find_first("mix:imageHeight", NAMESPACES).content)
    attribute_set(:compressionScheme, premis.find_first("mix:Compression", NAMESPACES).content)
    attribute_set(:colorSpace, premis.find_first("mix:colorSpace", NAMESPACES).content)  
    attribute_set(:orientation, premis.find_first("mix:orientation", NAMESPACES).content)  
    attribute_set(:sample_frequency_unit, premis.find_first("mix:", NAMESPACES).content)  
    attribute_set(:x_sampling_frequency, premis.find_first("mix:xSamplingFrequency", NAMESPACES).content)  
    attribute_set(:y_sampling_frequency, premis.find_first("mix:xSamplingFrequency", NAMESPACES).content)  
    attribute_set(:bits_per_sample, premis.find_first("mix:", NAMESPACES).content)  
    attribute_set(:samples_per_pixel, premis.find_first("mix:samplesPerPixel", NAMESPACES).content)  
    attribute_set(:extra_samples, premis.find_first("mix:extraSamples", NAMESPACES).content)  

  end
end