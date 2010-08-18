require 'data_mapper'

class Sip
  include DataMapper::Resource

  property :id, String, :key => true
  property :name, String
  property :size_in_bytes, Integer, :min => 0, :max => 2**63-1
  property :number_of_datafiles, Integer, :min => 0, :max => 2**63-1

  has n, :operations_events
  has n, :requests
  has 0..1, :aips

  belongs_to :project, :required => false

  # here's how the base string for the ieid is generated:
  # get a floating point representation of the current time
  # convert that floating point number to a string
  # remove the decimal point
  # convert the now decimal point less string into an integer object
  # use Integer's to_s method to get a base 36 representation
  #
  # TODO need something more entropic than time.
  #      payout of improving this is a decent payoff
  # TODO make this automagic for id?
  def Sip.next_old_id
    string = Time.now.to_f.to_s.gsub(".", "").to_i.to_s(36).upcase

    # pad with zeros to 14 characters
    string = ("0" * (14 - string.length)) + string

    # add underscore
    string = string.insert(8, "_")
    return "E" + string
  end

end
