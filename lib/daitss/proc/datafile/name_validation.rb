class DataFile
  def original_name_valid?
    return false if metadata["sip-path"] =~ /^\./
    return false if metadata["sip-path"] =~ /"/
    return false if metadata["sip-path"] =~ /'/
    return false if metadata["sip-path"] =~ / /

    true
  end
end
