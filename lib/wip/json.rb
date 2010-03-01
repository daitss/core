require 'json'
require 'wip'
require 'wip/state'
require 'wip/process'

class Wip

  def to_json *a

    hash = {
      :url => id,
      :running => (running? ? true : false),
      :done => (done? ? true : false),
      :snafu => (snafu? ? snafu : nil),
      :reject => (reject? ? reject : nil),
      :state => state,
      :task => task,
      :pid => pid,
      :pidTime => pid_time.to_f * 1000
    }

    hash.to_json *a
  end

end
