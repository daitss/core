DIGEST_CODES = { 
  "MD5" => :md5, # MD5 message digest algorithm, 128 bits
  "SHA-1" => :sha1, # Secure Hash Algorithm 1, 160 bits    
  "CRC32" => :crc32
}

ORIGINATOR = { 
  "archive" => :archive,
  "depositor" => :depositor
}

class MessageDigest
  include DataMapper::Resource
  property :id, Serial, :key => true
  # property :dfid, String, :length => 16, :key => true # :unique_index => :u1 
  property :code, Enum[:md5, :sha1, :crc32] #, :key=>true, :unique_index => :u1 
  property :value,  String, :required => true, :length => 255
  property :origin, Enum[:unknown, :archive, :depositor], :default => :unknown

  belongs_to :datafile #, :key => true#, :unique_index => :u1  the associated Datafile

  before :create, :check_unique_code 

  def check_unique_code 
    MessageDigest.first(:code => code, :datafile_id => datafile_id)
  end

  def fromPremis(premis)
    fixities = premis.find("premis:objectCharacteristics/premis:fixity", NAMESPACES)
    fixities.each do |fixity|
      code = fixity.find_first("premis:messageDigestAlgorithm", NAMESPACES).content
      attribute_set(:code, DIGEST_CODES[code])
      attribute_set(:value, fixity.find_first("premis:messageDigest", NAMESPACES).content)
      origin = fixity.find_first("premis:messageDigestOriginator", NAMESPACES)
      attribute_set(:origin, ORIGINATOR[origin.content.downcase]) if origin
    end
  end  

end