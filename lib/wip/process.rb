require 'sys/proctable'

class Wip

  def running?
    pid, starttime = process

    if pid and starttime
      p = Sys::ProcTable::ps pid.to_i

      if p
        starttime.tv_sec == p.starttime.tv_sec
      else
        false
      end

    else
      false
    end

  end


  def start
    unstop if stopped?

    unless running?

      pid = fork do
        %w(TERM INT QUIT HUP).each { |signal| Signal.trap signal, "DEFAULT" }
        #$stderr = StringIO.new
        yield self
        exit
      end

      Process.detach pid
      self.process = pid
    end

  end

  def kill signal="INT"

    while running?
      pid, starttime = process

      begin
        Process.kill signal, pid.to_i
        sleep 0.1 # overhead vs responsiveness: 1/100 of a second seems reasonable
      rescue Errno::ESRCH => e
        # nothing to do, this is OK
      end

    end

    tags.delete 'process'
  end

  def pid
    process.first if running?
  end

  def pid_time
    process.last if running?
  end

  private

  def process

    if tags.has_key? 'process'
      pid, time = tags['process'].split
      [pid.to_i, Time.at(time.to_i)]
    end

  end

  def process= pid
    p = Sys::ProcTable::ps pid.to_i
    tags['process'] = "#{pid} #{p.starttime.to_i}"
  end

end
