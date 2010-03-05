require 'wip'
require 'mark'

class Wip

  def step name
    key = step_key name

    if tags.has_key? key
      Mark.parse tags[key]
    else
      step!(name){ yield }
    end

  end

  def step! name
    key = step_key name
    m = Mark.new
    m.start
    value = yield
    m.finish
    tags[key] = m.to_s
    m
  end

  private 

  def step_key name
    "step.#{name}"
  end

end
