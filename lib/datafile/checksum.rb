require 'digest/md5'
require 'digest/sha1'
require 'xmlns'

class DataFile

  # Returns [sip descriptor checksum, computed checksum]
  def checksum_info
    expected = wip.sip_descriptor_checksum self

    if expected[:value] and ["MD5", "SHA-1", nil].include? expected[:type]

      actual_md = open do |io|

        case expected[:type]
        when "MD5" then Digest::MD5.hexdigest io.read
        when "SHA-1" then Digest::SHA1.hexdigest io.read
        when nil then infer expected[:value]
        end

      end

      [expected[:value], actual_md]
    else
      [nil,nil]
    end

  end

  private

  def infer s
    action_md = open do |io|
      case s
        when %r{^[a-fA-F0-9]{32}$} then Digest::MD5.hexdigest io.read
        when %r{^[a-fA-F0-9]{40}$} then  Digest::SHA1.hexdigest io.read
        else s
      end
    end
  end
end
