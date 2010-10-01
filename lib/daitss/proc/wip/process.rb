platform = `uname`.chomp

case platform
when "Linux"
  require 'linux/sys/proctable'
when "Darwin"
  require 'sys/proctable'
end

module Daitss

  class Wip

    OUT_LOG = 'out.log'
    ERR_LOG = 'err.log'

    # Returns true if the wip is running
    def running?
      pid, starttime = process

      if pid and starttime
        p = Sys::ProcTable::ps pid.to_i

        if p
          starttime.to_i == p.starttime.to_i
        else
          false
        end

      else
        false
      end

    end

    DBIN_PATH = File.join File.dirname(__FILE__), '..', '..', '..', '..', 'bin', 'dbin'

    # Starts a wip. if the wip is stopped the stopped stated is removed first.
    def start
      unstop if stopped?

      unless running?

        command = case task
                  when :ingest
                    [DBIN_PATH, "ingest", self.id]

                  when :disseminate
                    [DBIN_PATH, "disseminate", self.id]

                  when :sleep
                    %w(sleep 1000)

                  else raise "invalid task: #{task}"
                  end

        pid = fork do
          $stdout.reopen File.join(self.path, OUT_LOG), 'w'
          $stderr.reopen File.join(self.path, ERR_LOG), 'w'
          exec *command
        end

        Process.detach pid
        self.process = pid
      end

    end

    # Kills the process operating on a wip. +signal+ by default is +INT+. any
    # valid signal may be passed.
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

    # Returns the pid of the process operating on the wip
    def pid
      process.first if running?
    end

    # Returns the time when the process was started
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

end
