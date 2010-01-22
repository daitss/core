require 'uuid'

class Ieid
  @ieid

  # generate a new UUID, strip out dashes, convert to base 36, re-introduce dashes for readability
  def initialize
    generator = UUID.new

    uuid = generator.generate(:compact)

    integer_rep = uuid.hex
    base_36_rep = integer_rep.to_s(36)

    @ieid = dashify base_36_rep
  end

  def to_s
    @ieid
  end

  private

  # inserts dashes to make IEID easier to read
  
  def dashify string
    string = string.insert(4, "-")
    string = string.insert(9, "-")
    string = string.insert(14, "-")
    string = string.insert(19, "-")
    string = string.insert(24, "-")

    return string
  end
end
