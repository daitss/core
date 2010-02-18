require 'wip'

class Wip

  def step name
    key = step_key name

    unless tags.has_key? key
      value = yield
      tags[key] = Time.now.xmlschema
      value
    end

  end

  def step! name
    key = step_key name
    value = yield
    tags[key] = Time.now.xmlschema
    value
  end

  def step_time name
    key = step_key name
    Time.parse tags[key] if tags.has_key? key
  end

  private 
  
  def step_key name
    "step-#{name}"
  end

end
