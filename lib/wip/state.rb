require 'wip'
require 'wip/snafu'
require 'wip/reject'
require 'wip/task'
require 'wip/process'

class Wip

  def state

    if running?
      'running'
    elsif snafu?
      'snafu'
    elsif reject?
      'reject'
    elsif task_complete?
      'complete'
    else
      'idle'
    end

  end

end
