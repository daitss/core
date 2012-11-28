require 'mixin/file'
require 'daitss/profile'


case PLATFORM
when /linux/i
  require 'linux/sys/proctable'
when /darwin/i
  require 'sys/proctable'
end

module Daitss

  class Wip

    OUT_LOG = 'out.log'
    ERR_LOG = 'err.log'

    def out_path
      File.join @path, OUT_LOG
    end

    def err_path
      File.join @path, ERR_LOG
    end

    def std_data
      out = File.read out_path if File.exist? out_path
      err = File.read err_path if File.exist? err_path
      [out, err]
    end

    def need_state s
      raise "#{s} state is required, not #{state}" unless s == state
    end

    def stash_journal
      jf = File.join @path, 'journal'
      pf = profile_file('journal', id, task) 
      FileUtils.cp jf, pf if File.exist? jf
    end

    def do_over note=nil, agent=nil
      stop if running?

      package.log "#{task} do over", :notes => note, :agent => agent

      File.lock @path, :shared => true do
        reset_journal
      end
    end

    def procname
      "#{id}.#{task}" # github #574
    end

    # start a wip's task in a new process
    def spawn note=nil, agent = nil
      need_state :idle
      
      agent = Program.get("SYSTEM") unless agent

      # if this isn't here the fork can break do
      DataObjects::Pooling.pools.each &:dispose

      pid = fork do
        $0 = procname
        Signal.trap('INT', 'DEFAULT')
        $stdout.reopen out_path, 'w'
        $stderr.reopen err_path, 'w'

        profile_start

        begin

          if note and !note.empty?
            package.log "#{task} started", :notes => note, :agent => agent
          else
            package.log "#{task} started", :agent => agent
          end

          send task
          package.log "#{task} finished"
          stash_journal
          retire
        rescue => e
          make_snafu e
          package.log "#{task} snafu", :notes => e.message.split("\n\n")[0]
          stash_journal
        end

        profile_stop id, task
      end

      @process = {
        :id => pid.to_i,
        :time => Sys::ProcTable.ps(pid.to_i).starttime
      }

      save_process
      Process.detach pid
      sleep 0.5
    end

    # atomically delete a wip from the workspace
    def retire
      die_path = File.join archive.nuke_path, id
      File.lock(@path) { FileUtils.mv @path, die_path }
      FileUtils.rm_r die_path
    end

    def done?
      not File.exist? @path
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
      return false if done?
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
      return false if done?
      !running? and @process and @process[:id].kind_of?(Fixnum)
    end

    # stop a running process
    def stop note=nil, agent = nil
      need_state :running
      kill
      @process = { :id => :stop, :time => Time.now }
      save_process

      agent = Program.get("SYSTEM") unless agent

      if note and !note.empty?
        package.log "#{task} stopped", :notes => note, :agent => agent
      else
        package.log "#{task} stopped", :agent => agent
      end

    end

    # return true of a process is stopped
    def stopped?
      return false if done?
      load_process
      !@process.nil? and @process[:id] == :stop
    end

    # remove the stopped state
    def unstop
      need_state :stop
      reset_process
    end

    # snafu a running process
    def make_snafu e

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
      return false if done?
      load_process
      @process and @process[:id] == :snafu
    end

    # resets the state of a package if it is snafu
    def unsnafu note=nil, agent = nil
      # allow resetting of dead process
      unless dead?
        need_state :snafu
      end
      
      reset_process

      agent = Program.get("SYSTEM") unless agent

      if note and !note.empty?
        package.log "#{task} unsnafu", :notes => note, :agent => agent
      else
        package.log "#{task} unsnafu", :agent => agent
      end

    end

    # @return [Boolean] if WIP is startable

    def startable?
      not (done? or running? or snafu? or stopped? or dead?)
    end

    # returns a symbol denoting the state of a wip
    def state

      if done? then :done
      elsif running? then :running
      elsif dead? then :dead
      elsif @process.nil? then :idle
      else @process[:id]
      end

    end

  end

end
