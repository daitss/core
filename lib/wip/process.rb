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

  def done?

    if not(running?) and tags.has_key?('done')
      Time.parse tags['done'] rescue false
    else
      false
    end

  end

  def start

    unless running?

      pid = fork do 
        $stderr = StringIO.new # silencio!
        #$stdout = StringIO.new
        yield self
        tags['done'] = Time.now.xmlschema
        exit
      end

      Process::detach pid
      self.process = pid
    end

  end

  def stop

    while running?
      pid, starttime = process
      Process::kill "INT", pid.to_i
      sleep 0.1 # overhead vs responsiveness: 1/10 of a second seems reasonable
    end

    tags.delete 'process'
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
