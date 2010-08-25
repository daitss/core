require 'data_mapper'

class EggHeadKey < DataMapper::Property::String
  key true
  default proc { |res, prop| EggHeadKey.new_egg_head_key }

  # here's how the base string for the ieid is generated:
  # get a floating point representation of the current time
  # convert that floating point number to a string
  # remove the decimal point
  # convert the now decimal point less string into an integer object
  # use Integer's to_s method to get a base 36 representation
  #
  # TODO need something more entropic than time.
  #      payout of improving this is a decent payoff
  def EggHeadKey.new_egg_head_key
    string = ::Time.now.to_f.to_s.gsub(".", "").to_i.to_s(36).upcase

    # pad with zeros to 14 characters
    string = ("0" * (14 - string.length)) + string

    # add underscore
    string = string.insert(8, "_")
    return "E" + string
  end

end
