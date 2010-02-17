# Please see mix 2.0 data dictionary for the compression scheme value
Compression_Scheme = { 
  "Unknown" => :unknown,
  "Uncompressed" => :Uncompressed,
  "CCITT Group 4" => :CCITT_Group_4,
  "LZW" => :LZW,
  "JPEG" => :JPEG_BasedlineSequential,
  "JPEG 2000 Lossy" => :JPEG_2000_Lossy,
  "JPEG 2000 Lossless" => :JPEG_2000_Lossless,
  "JBIG2" => :JBIG2,
  "Deflate/zlib" => :Deflate_zlib 
  }
  
# Please see mix 2.0 data dictionary for the color space value  
Color_Space = {
  "WhiteIsZero" => :WhiteIsZero,
  "BlackIsZero" => :BlackIsZero,
  "RGB" => :RGB,
  "PaletteColor" => :PaletteColor,
  "TransparencyMask" => :TransparencyMask,
  "CMYK" => :CMYK,
  "YCbCr" => :YCbCr,
  "CIELab" => :CIELab,
  "ICCLab" => :ICCLab,
  "DeviceGray" => :DeviceGray,
  "DeviceRGB" => :DeviceRGB,
  "DeviceCMYK" => :DeviceCMYK,
  "CalGray" => :CalGray,
  "CalRGB" => :CalRGB,
  "Lab" => :Lab,
  "ICCBased" => :ICCBased,
  "Separation" => :Separation,
  "sRGB" => :sRGB,
  "e-sRGB" => :e_sRGB,
  "sYCC" => :sYCC,
  "Indexed" => :Indexed,
  "Pattern" => :Pattern,
  "DeviceN" => :DeviceN,
  "YCCK" => :YCCK,
  "Other" => :Other
  }
  
# Please see mix 2.0 data dictionary for descriptions on sampling frequency
Sample_Frequency_Unit = {
  "no absolute unit of measurement" => :no_absolute_unit_of_measurement,
   "in" => :inch, 
   "cm" => :centimeter
}

class Image
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :width, Integer # positive integer, TODO min = 0
    # the width of the image, in pixels.
  property :height, Integer  # positive int, TODO min = 0
    # the height of the image, in pixels.
  property :compressionScheme, Enum[:unknown, :Uncompressed, :CCITT_Group_4, :LZW, :JPEG_BasedlineSequential, 
    :JPEG_2000_Lossy, :JPEG_2000_Lossless, :JBIG2, :Deflate_zlib], :default => :unknown
    # compression scheme used to store the image data
  property :colorSpace, Enum[:unknown, :WhiteIsZero, :BlackIsZero, :RGB, :PaletteColor, :TransparencyMask, 
    :CMYK, :YCbCr, :CIELab, :ICCLab, :DeviceGray, :DeviceRGB, :DeviceCMYK, :CalGray, :CalRGB, :Lab,
    :ICCBased, :Separation, :sRGB, :e_sRGB, :sYCC, :Indexed, :Pattern, :DeviceN, :YCCK], :default => :unknown
    # the color model of the decompressed image
  property :orientation, Enum[:normal, :flipped, :rotated_180, :flipped_rotated_180, :flipped_rotated_cw_90,
    :rotated_ccw_90, :flipped_rotated_ccw_90, :rotated_cw_90, :unknown], :default => :unknown
    # orientation of the image, with respect to the placement of its width and height.
  property :sample_frequency_unit, Enum[:no_absolute_unit_of_measurement, :inch, :centimeter]
    # the unit of measurement for x and y sampling frequency
  property :x_sampling_frequency, Float
    # the number of pixels per sampling frequency unit in the image width
  property :y_sampling_frequency, Float
    # the number of pixels per sampling frequency unit in the image height
  property :bits_per_sample, String # use value "1", "4", "8", "8,8,8", "8,2,2", "16,16,16", "8,8,8,8"] 
    # the number of bits per component for each pixel
  property :samples_per_pixel, Integer # positive int, TODO min = 0
    # the number of color components per pixel
  property :extra_samples, Enum[:unspecified_data, :associated_alpha_data, :unassociated_alpha_data, :range_data]
    # specifies that each pixel has M extra components whose interpretation is defined as above
    
  belongs_to :datafile, :index => true # Image may be associated with a Datafile, 
     # null if the image is associated with a bitstream
  belongs_to :bitstream, :index => true # Image may be associated with a bitstream, 
     # null if the image is associated with a datafile
  
  def setDFID dfid
    attribute_set(:datafile_id, dfid)
  end

  def setBFID bfid
    attribute_set(:bitstream_id, bfid)
  end
    
  def fromPremis premis
    attribute_set(:width, premis.find_first("mix:BasicImageInformation/mix:BasicImageCharacteristics/mix:imageWidth", NAMESPACES).content)
    attribute_set(:height, premis.find_first("mix:BasicImageInformation/mix:BasicImageCharacteristics/mix:imageHeight", NAMESPACES).content)
    compressionScheme = premis.find_first("mix:BasicDigitalObjectInformation/mix:Compression/mix:compressionScheme", NAMESPACES)
    attribute_set(:compressionScheme, Compression_Scheme[compressionScheme.content]) unless compressionScheme.nil?
    colorspace = premis.find_first("mix:BasicImageInformation/mix:BasicImageCharacteristics/mix:PhotometricInterpretation/mix:colorSpace", NAMESPACES)
    attribute_set(:colorSpace, Color_Space[colorspace.content]) unless colorspace.nil?
    # TODO: attribute_set(:orientation, premis.find_first("mix:orientation", NAMESPACES).content)  
    sfu = premis.find_first("mix:ImageAssessmentMetadata/mix:SpatialMetrics/mix:samplingFrequencyUnit", NAMESPACES)
    attribute_set(:sample_frequency_unit, Sample_Frequency_Unit[sfu.content]) unless sfu.nil?
    xsf = premis.find_first("mix:ImageAssessmentMetadata/mix:SpatialMetrics/mix:xSamplingFrequency", NAMESPACES)
    unless xsf.nil?
     if xsf.find_first("mix:denominator", NAMESPACES)
       xsfv = xsf.find_first("mix:numerator", NAMESPACES).content.to_f / xsf.find_first("mix:denominator", NAMESPACES).content.to_f
     else
       xsfv = xsfv = xsf.find_first("mix:numerator", NAMESPACES).content.to_f 
     end
     attribute_set(:x_sampling_frequency, xsfv)
    end
    ysf = premis.find_first("mix:ImageAssessmentMetadata/mix:SpatialMetrics/mix:ySamplingFrequency", NAMESPACES)
    unless ysf.nil?
      if ysf.find_first("mix:denominator", NAMESPACES)
        ysfv = ysf.find_first("mix:numerator", NAMESPACES).content.to_f / ysf.find_first("mix:denominator", NAMESPACES).content.to_f 
      else
        ysfv = ysf.find_first("mix:numerator", NAMESPACES).content.to_f
      end
      attribute_set(:y_sampling_frequency,  ysfv) 
    end
    bpsv_list = premis.find("mix:ImageAssessmentMetadata/mix:ImageColorEncoding/mix:BitsPerSample/mix:bitsPerSampleValue", NAMESPACES)
    bps = Array.new
    bpsv_list.each {|value| bps << value.content}
    attribute_set(:bits_per_sample, bps.join(","))
    spp = premis.find_first("mix:ImageAssessmentMetadata/mix:ImageColorEncoding/mix:samplesPerPixel", NAMESPACES)
    attribute_set(:samples_per_pixel, spp.content) unless spp.nil?
    # TODO: attribute_set(:extra_samples, premis.find_first("mix:extraSamples", NAMESPACES).content)  
  end

  before :save do
    # make sure either dfid or bsid is not null.
    if (:datafile_id.nil? && :bitstream_id.nil?)
      raise "this image neither associates with a datafile nor associates with a bitstream"
    end 
  end
end