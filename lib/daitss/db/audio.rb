require 'data_mapper'

# byte order values as defined in aes
Audio_Byte_Order = ["BIG_ENDIAN", "LITTLE_ENDIAN", "Unknown"]

class Audio
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :byte_order, String, :length => 32, :required => true, :default => "Unknown"
 	validates_with_method :byte_order, :validateByteOrder
    # byte order
  property :encoding, String, :length => 255
    # the audio encoding scheme
  property :sampling_frequency, Float
    # the number of audio samples that are recorded per second (in Hertz, i.e. cycles per second)
  property :bit_depth, Integer # TODO positive int
    # the number of bits used each sample to represent the audio signal
  property :channels, Integer # TODO positive int
    # the number of channels that are part of the audio stream
  property :duration, Integer
    # the length of the audio recording, described in seconds
  property :channel_map, String, :length => 64
    # channel mapping, mono, stereo, etc, TBD
    
  property :datafile_id, String, :length => 100
  property :bitstream_id, String, :length => 100
  
  # validate the audio byte order value which is a daitss defined controlled vocabulary
  def validateByteOrder
      if Audio_Byte_Order.include?(@byte_order)
        return true
      else
        [ false, "value #{@byte_order} is not a valid byte_order value" ]
      end
    end

  def setDFID dfid
    attribute_set(:datafile_id, dfid)
  end

  def setBFID bsid
    attribute_set(:bitstream_id, bsid)
  end
    
  def fromPremis premis
	byte_order = premis.find_first("aes:byte_order", NAMESPACES)
  	attribute_set(:byte_order, byte_order.content) if byte_order
    attribute_set(:encoding, premis.find_first("aes:audioDataEncoding", NAMESPACES).content)
    attribute_set(:sampling_frequency, premis.find_first("aes:formatList/aes:formatRegion/aes:sampleRate", NAMESPACES).content)
    attribute_set(:bit_depth, premis.find_first("aes:formatList/aes:formatRegion/aes:bitDepth", NAMESPACES).content)
    attribute_set(:channels, premis.find_first("aes:face/aes:region/aes:numChannels", NAMESPACES).content)  

    # calculate the duration in number of seconds, make sure timeline/duration exist
    if premis.find_first("aes:face/aes:timeline/tcf:duration")
      hours = premis.find_first("aes:face/aes:timeline/tcf:duration/tcf:hours", NAMESPACES).content
      minutes = premis.find_first("aes:face/aes:timeline/tcf:duration/tcf:minutes", NAMESPACES).content
      seconds = premis.find_first("aes:face/aes:timeline/tcf:duration/tcf:seconds", NAMESPACES).content  
      durationInS = seconds.to_i + minutes.to_i * 60 + hours.to_i * 3600
      attribute_set(:duration, durationInS)
    end

	if node = premis.find_first("//@mapLocation", NAMESPACES)
	  puts node.inspect
      channelMap = node.value 
      attribute_set(:channel_map, channelMap)
	end 
  end
  
  before :save do
    # make sure either dfid or bsid is not null.
    if (:datafile_id.nil? && :bitstream_id.nil?)
      raise "this audio neither associates with a datafile nor associates with a bitstream"
    end 
  end

  after :save do
    puts self.methods
    puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
  end

end
