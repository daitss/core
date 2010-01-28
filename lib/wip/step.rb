require 'wip'

class Wip

  def step key

    unless tags.has_key? key
      value = yield
      tags[key] = Time.now.xmlschema
      value
    end

  end

  def step_time key
    Time.parse tags[key] if tags.has_key? key
  end

end
