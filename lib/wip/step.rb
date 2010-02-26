require 'wip'

class Wip

  def step name
    key = step_key name

    unless tags.has_key? key
      start_time = Time.now
      value = yield
      end_time = Time.now
      tags[key] = "#{start_time.xmlschema 4} #{end_time.xmlschema 4}"
      value
    end

  end

  def step! name
    key = step_key name

    start_time = Time.now
    value = yield
    end_time = Time.now
    tags[key] = "#{start_time.xmlschema 4} #{end_time.xmlschema 4}"
    value
  end

  def step_start_time name
    key = step_key name
    start_time, end_time = tags[key].split(' ').map { |t| Time.parse t } if tags.has_key? key
    end_time
  end

  def step_end_time name
    key = step_key name
    start_time, end_time = tags[key].split(' ').map { |t| Time.parse t } if tags.has_key? key
    end_time
  end

  def duration name
    key = step_key name
    start_time, end_time = tags[key].split(' ').map { |t| Time.parse t } if tags.has_key? key
    end_time - start_time
  end
  private 

  def step_key name
    "step-#{name}"
  end

end
