require 'json'
require 'wip'
require 'wip/state'
require 'wip/process'

class Wip

  def to_json *a

    hash = {
      :id => id,
      :uri => uri,
      :running => (running? ? true : false),
      :task_complete => (task_complete? ? true : false),
      :snafu => (snafu? ? snafu : nil),
      :state => state,
      :task => task,
      :pid => pid,
      :pidTime => pid_time.to_f * 1000
    }

    hash.to_json *a
  end

end
