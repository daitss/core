require 'daitss/proc/wip'
require 'daitss/proc/wip/snafu'
require 'daitss/proc/wip/task'
require 'daitss/proc/wip/process'

class Wip

  def state

    if running? then 'running'
    elsif stopped? then 'stopped'
    elsif snafu? then 'snafu'
    else 'idle'
    end

  end

end
