require "db/operations_events"

# generates DAITSS 1 style IEIDs

class OldIeid

  INITIAL_VALUE = 345901837697478033408 # decimal representation of the base 36 number 21000000000000
  
  def self.get_next
    # get most recent submission event with DAITSS 1 style IEID from database and increment it
    record = OperationsEvent.all(:order => [ :ieid.desc ], :limit => 1, :ieid.like => 'E%' )

    if record.length > 0
      # convert string IEID to an integer
      last_id = record.pop.ieid
      num = last_id.gsub("_", "").gsub("E","").to_i(36)

      return generate_ieid(num + 1)
    else
      return generate_ieid INITIAL_VALUE
    end
  end
  
  private

  # returns an IEID based on integer passed in
  def self.generate_ieid integer
      # increment and convert back to a string
      string = integer.to_s(36)

      # pad with zeros to 14 characters
      ieid = ("0" * (14 - string.length)) + string

      # add underscore
      ieid = ieid.insert(8, "_")
      return "E" + ieid.upcase
  end
end
