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

    def need_state s
      raise "#{s} state is required, not #{state}" unless s == state
    end

    # start a wip's task in a new process
    def spawn
      need_state :idle

      pid = fork do
        $0 = "#{id}.#{task}"
        Signal.trap('INT', 'DEFAULT')
        $stdout.reopen File.join(self.path, OUT_LOG), 'w'
        $stderr.reopen File.join(self.path, ERR_LOG), 'w'
        #archive.setup_db

        begin
          package.log "#{task} started"
          send task
          package.log "#{task} finished"
          FileUtils.rm_r path unless snafu? or dead?
        rescue => e
          self.snafu = e
          package.log "#{task} snafu", :notes => e.message.split("\n\n")[0]
          exit 1
        end

      end

      @process = {
        :id => pid.to_i,
        :time => Sys::ProcTable.ps(pid.to_i).starttime
      }

      save_process
      Process.detach pid
      sleep 0.5
    end

    # Kills the process operating on a wip. +signal+ by default is +INT+. any
    # valid signal may be passed.
    def kill signal="INT"
      need_state :running

      begin
        Process.kill signal, process[:id]

        # overhead vs responsiveness: 1/100 of a second seems reasonable
        sleep 0.1 while running?
      rescue Errno::ESRCH => e
        # nothing to do, this is OK
      end

      reset_process
    end

    # return true if the wip is running
    def running?
      load_process

      if @process and @process[:id].kind_of? Fixnum
        p = Sys::ProcTable.ps @process[:id]

        if p
          p.starttime.to_i == @process[:time].to_i
        end

      end

    end

    # return true if the process is dead
    def dead?
      !running? and @process and @process[:id].kind_of?(Fixnum)
    end

    # stop a running process
    def stop
      need_state :running
      kill
      @process = { :id => :stop, :time => Time.now }
      save_process
    end

    # return true of a process is stopped
    def stopped?
      load_process
      !@process.nil? and @process[:id] == :stop
    end

    # remove the stopped state
    def unstop
      need_state :stop
      reset_process
    end

    # snafu a running process
    def snafu= e

      @process = {
        :id => :snafu,
        :time => Time.now,
        :message => e.message,
        :backtrace => e.backtrace
      }

      save_process
    end

    # returns true if this wip is snafu
    def snafu?
      load_process
      @process and @process[:id] == :snafu
    end

    # resets the state of a package if it is snafu
    def unsnafu
      need_state :snafu
      reset_process
    end

    # returns a symbol denoting the state of a wip
    def state

      if running? then :running
      elsif dead? then :dead
      elsif @process.nil? then :idle
      else @process[:id]
      end

    end

  end

end
