module SipHelpers

  def sip_fixture sip
    dir = File.dirname __FILE__
    file = sip + ".zip"
    File.join dir, *%w(.. sips), file
  end

end

World(SipHelpers)
