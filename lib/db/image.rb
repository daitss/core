# Please see mix 2.0 data dictionary for byte order values
Image_Byte_Order = ["big endian", "little endian", "Unknown"]

# Please see mix 2.0 data dictionary and NISO data in JHOVE for the compression scheme value
Compression_Scheme = ["Unknown", "Uncompressed", "CCITT 1D", "CCITT Group 3", "CCITT Group 4", "LZW", "JPEG",  "ISO JPEG",  "Deflate",
   "JBIG", "RLE with word alignment", "PackBits", "NeXT 2-bit encoding", "ThunderScan 4-bit encoding", "RasterPadding in CT or MP",   
    "RLE for LW", "RLE for HC", "RLE for BL","Pixar 10-bit LZW",  "Pixar companded 11-bit ZIP encoding", "PKZIP-style Deflate encoding", "Kodak DCS",    
    "SGI 32-bit Log Luminance encoding",  "SGI 24-bit Log Luminance encoding", "JPEG 2000" ]

# mapping of characterization output to MIX 2.0
Compression_Scheme_Map = {
	"uncompressed" => "Uncompressed",
	"Group 4 Fax" => "CCITT Group 4"
}

# Please see mix 2.0 data dictionary for the color space value
Color_Space = ["Unknown", "WhiteIsZero", "BlackIsZero", "RGB", "PaletteColor", "TransparencyMask", "CMYK",
  "YCbCr", "CIELab", "ICCLab", "DeviceGray", "DeviceRGB", "DeviceCMYK", "CalGray", "CalRGB",
  "Lab", "ICCBased", "Separation", "sRGB", "e-sRGB", "sYCC", "Indexed", "Pattern", "DeviceN",
  "YCCK", "Other" ]

# mapping of characterization output to MIX 2.0
Color_Space_Map = {
	"white is zero" => "WhiteIsZero",
	"black is zero" => "BlackIsZero",
	"palette color" => "PaletteColor",
	"transparency mask" => "TransparencyMask",
	"CIE L*a*b*" =>  "CIELab",
	"ICC L*a*b*" => "ICCLab",
	"ITU L*a*b*" => "Other",
  	"CFA" => "Other",
  	"CIE Log2(L)" => "Other",
  	"CIE Log2(L)(u',v')" => "Other",
  	"LinearRaw" => "Other"
}

Orientation = ["Unknown", "normal", "flipped", "rotated 180", "flipped rotated 180", "flipped rotated cw 90",
    "rotated ccw 90", "flipped rotated ccw 90", "rotated cw 90"]

# Please see mix 2.0 data dictionary for descriptions on sampling frequency
Sample_Frequency_Unit = ["no absolute unit of measurement", "inch", "centimeter"]
Sample_Frequency_Unit_Map = {
  "in." => "inch", 
  "cm" => "centimeter"
}

Extra_Samples = ["unspecified data", "associated alpha data", "unassociated alpha data", "range or depth data"]

class Image
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :byte_order, String, :length => 32, :required => true, :default => "Unknown"
    # byte order
  property :width, Integer, :min => 0
    # the width of the image, in pixels.
  property :height, Integer, :min => 0
    # the height of the image, in pixels.
  property :compression_scheme, String, :length => 64, :required => true, :default => "Unknown"
	validates_with_method :compression_scheme, :method => :validate_compression_scheme
    # compression scheme used to store the image data
  property :color_space,  String, :length => 64, :required => true, :default => "Unknown"
	validates_with_method :color_space, :method => :validate_color_space
    # the color model of the decompressed image
  property :orientation, String, :length => 32, :required => true, :default => "Unknown"
	validates_with_method :orientation, :method => :validate_orientation
    # orientation of the image, with respect to the placement of its width and height.
  property :sample_frequency_unit, String, :length => 64, :required => true, :default => "no absolute unit of measurement"
	validates_with_method :sample_frequency_unit, :method => :validate_sample_frequency_unit
    # the unit of measurement for x and y sampling frequency
  property :x_sampling_frequency, Float
    # the number of pixels per sampling frequency unit in the image width
  property :y_sampling_frequency, Float
    # the number of pixels per sampling frequency unit in the image height
  property :bits_per_sample, String, :length => 255 # use value "1", "4", "8", "8,8,8", "8,2,2", "16,16,16", "8,8,8,8"]
    # the number of bits per component for each pixel
  property :samples_per_pixel, Integer # positive int, TODO min = 0
    # the number of color components per pixel
  property :extra_samples, String, :length => 255, :required => true, :default => "unspecified data"
    # specifies that each pixel has M extra components whose interpretation is defined as above

  property :datafile_id, String, :length => 100
  property :bitstream_id, String, :length => 100
  # belongs_to :datafile, :index => true # Image may be associated with a Datafile,
     # null if the image is associated with a bitstream
  # belongs_to :bitstream, :index => true # Image may be associated with a bitstream,
     # null if the image is associated with a datafile

  def validate_compression_scheme
      if Compression_Scheme.include?(@compression_scheme)
        return true
      else
        [ false, "value #{@compression_scheme} is not a valid image compression scheme" ]
      end
    end

  def validate_color_space
      if Color_Space.include?(@color_space)
        return true
      else
        [ false, "value #{@color_space} is not a valid image color space" ]
      end
    end

  def validate_orientation
      if Orientation.include?(@orientation)
        return true
      else
        [ false, "value #{@orientation} is not a valid image orientation" ]
      end
    end

  def validate_sample_frequency_unit
      if Sample_Frequency_Unit.include?(@sample_frequency_unit)
        return true
      else
        [ false, "value #{@sample_frequency_unit} is not a valid image sampling frequency unit" ]
      end
    end

  def setDFID dfid
    attribute_set(:datafile_id, dfid)
  end

  def setBFID bfid
    attribute_set(:bitstream_id, bfid)
  end

  def fromPremis premis
	byte_order = premis.find_first("mix:BasicDigitalObjectInformation/mix:byteOrder", NAMESPACES)
	attribute_set(:byte_order, byte_order.content) if byte_order
    attribute_set(:width, premis.find_first("mix:BasicImageInformation/mix:BasicImageCharacteristics/mix:imageWidth", NAMESPACES).content)
    attribute_set(:height, premis.find_first("mix:BasicImageInformation/mix:BasicImageCharacteristics/mix:imageHeight", NAMESPACES).content)
    compressionScheme = premis.find_first("mix:BasicDigitalObjectInformation/mix:Compression/mix:compressionScheme", NAMESPACES)
    if compressionScheme
	  if Compression_Scheme.include?(compressionScheme.content)
        attribute_set(:compression_scheme, compressionScheme.content) 
	  elsif Compression_Scheme_Map[compressionScheme.content]
		attribute_set(:compression_scheme, Compression_Scheme_Map[compressionScheme.content]) 
	  else
	    raise "unrecognized compression scheme #{compressionScheme.content}"
	  end
	end
    colorspace = premis.find_first("mix:BasicImageInformation/mix:BasicImageCharacteristics/mix:PhotometricInterpretation/mix:colorSpace", NAMESPACES)

    if colorspace
	  if Color_Space.include?(colorspace.content)
        attribute_set(:color_space, colorspace.content) 
	  elsif Color_Space_Map[colorspace.content]
		attribute_set(:color_space, Color_Space_Map[colorspace.content]) 
	  else
	    raise "unrecognized color space #{colorspace.content}"
	  end
	end   
    # TODO: attribute_set(:orientation, premis.find_first("mix:orientation", NAMESPACES).content)
    sfu = premis.find_first("mix:ImageAssessmentMetadata/mix:SpatialMetrics/mix:samplingFrequencyUnit", NAMESPACES)
    if sfu
	  if Sample_Frequency_Unit.include?(sfu.content)
        attribute_set(:sample_frequency_unit, sfu.content) 
	  elsif Sample_Frequency_Unit_Map[sfu.content]
		attribute_set(:sample_frequency_unit, Sample_Frequency_Unit_Map[sfu.content]) 
	  else
	    raise "unrecognized sampling frequency unit #{sfu.content}"
	  end
	end
	
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

  after :save do
    puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
  end
end
