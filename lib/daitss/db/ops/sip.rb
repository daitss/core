require 'data_mapper'

require 'daitss/db/ops/aip'
require 'daitss/db/ops/operations_events'

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

class Sip
  include DataMapper::Resource

  property :id, EggHeadKey
  property :name, String
  property :size_in_bytes, Integer, :min => 0, :max => 2**63-1
  property :number_of_datafiles, Integer, :min => 0, :max => 2**63-1

  has n, :operations_events
  has n, :requests
  #has 0..1, :aips

  belongs_to :project, :required => false

  def Sip.from_sip_archive sa
    sip = Sip.new
    sip.name = sa.name

    if sa.valid?
      sip.number_of_datafiles = sa.files.size

      sip.size_in_bytes = sa.files.inject(0) do |sum, f|
        path = File.join sa.path, f
        sum + File.size(path)
      end

    end

    sip
  end

  # add an operations event for abort
  def abort user
    event = OperationsEvent.new :event_name => 'abort'
    event.operations_agent = user
    event.sip = self
    event.timestamp = Time.now
    event.save or raise "cannot save op event"
  end

end
