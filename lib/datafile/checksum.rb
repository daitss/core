require 'digest/md5'
require 'digest/sha1'
require 'xmlns'

class DataFile

  # Returns [sip descriptor checksum, computed checksum]
  def checksum_info
    expected = wip.sip_descriptor_checksum self

    if expected[:value]

      actual_md = open do |io|

        case expected[:type]
        when "MD5" then Digest::MD5.hexdigest io.read
        when "SHA-1" then Digest::SHA1.hexdigest io.read
        when nil then infer expected[:value]
        else raise "Unsupported checksum type: #{expected[:type]}"
        end

      end

      [expected[:value], actual_md]
    else
      [nil,nil]
    end

  end

  private

  def infer s

    case s
    when %r{[a-fA-F0-9]{40}} then Digest::MD5.hexdigest io.read
    when %r{[a-fA-F0-9]{32}} then  Digest::SHA1.hexdigest io.read
    else raise "Missing checksum type: Provided checksum: #{s}"
    end

  end

end
