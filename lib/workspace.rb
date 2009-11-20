class Workspace

  # make a new worksapce out of a directory
  def initialize dir
    @dir = dir
  end

  # start ingests for a package (:all for any ingestable package)
  def start target, config_file

    aips = if target == :all
             pending + tagged_with("STOP")
           else
             aip = target
             raise "#{aip} is not in the workspace" unless in_here? aip
             raise "#{aip} is ingesting" if ingesting? aip
             raise "#{aip} is SNAFU" if File.exists? File.join(@dir, aip, "SNAFU")
             raise "#{aip} is REJECTED" if File.exists? File.join(@dir, aip, "REJECT")
             [aip]
           end

    aips.each do |aip|
      FileUtils::rm_rf File.join(@dir, aip, "STOP")
      path = File.join @dir, aip
      pid = fork { exec "ruby -Ilib bin/ingest -aip #{path} -config #{config_file}" }
      append_state aip, pid
    end

  end

  # stops ingests for a package (:all for any ingesting package)
  def stop target

    raise "#{target} is not ingesting" unless target == :all and ingesting? target
    
    kill_pred = if target == :all
                  lambda { |aip, pid| true }
                else                     
                  lambda { |aip, pid| aip == target }
                end

    to_kill, to_keep = read_state.partition &kill_pred
puts to_kill.inspect
puts to_keep.inspect
    to_kill.each do |aip, pid|
      
      begin
        Process.kill "INT", pid.to_i
      rescue Errno::ESRCH
        # OK if its done
      ensure
        FileUtils.touch File.join(@dir, aip, "STOP")
      end
      
    end

    write_state to_keep
  end

  def pending

    in_here.reject do |aip|
      %(REJECT SNAFU STOP).any? { |tag| File.exist? File.join(@dir, aip, tag) } or ingesting?(aip)
    end

  end

  def ingesting
    read_state.map { |aip, pid| aip }
  end

  def ingesting? aip
    ingesting.include? aip
  end

  def tagged_with tag
    in_here.select { |aip| File.exists? File.join(aip, tag)  }
  end

  def all_with_status

    in_here.map do |aip|
      state = "pending"
      state = "ingesting" if ingesting? aip
      state = "STOP" if File.file? File.join(@dir, aip, "STOP")
      state = "REJECT" if File.file? File.join(@dir, aip, "REJECT")
      state = "SNAFU" if File.file? File.join(@dir, aip, "SNAFU")
      "#{File.basename aip} #{state}"
    end

  end

  def stash aip, destination
    raise "#{aip} is ingesting" if ingesting? aip
    FileUtils::mv File.join(@dir, aip), File.join(destination, aip)
  end

  def unsnafu aip
    raise "#{aip} is not SNAFU" if aip != :all and !File.exist? File.join(@dir, aip, "SNAFU")
    pattern = File.join @dir, (aip == :all ? "*" : aip), "SNAFU"
    Dir[pattern].each { |tag| FileUtils::rm tag }
  end

  private
  
  # the file that stores the state
  def state_file
    File.join @dir, ".boss"
  end

  # read the state into an array of entries
  def read_state

    begin

      open(state_file) do |io|
        io.readlines.map { |line| line.chomp.split }
      end

    rescue Errno::ENOENT
      []
    end

  end

  # write an arrary of entries as the state
  def write_state state

    open(state_file, "w") do |io|
      state.each { |aip, pid| io.puts "#{aip} #{pid}" }
    end

  end

  # append an entry to the state
  def append_state aip, pid
    open(state_file, "a") { |io| io.puts "#{aip} #{pid}" }
  end

  # returns all aips paths in the workspace
  def in_here
    Dir[ File.join(@dir, "*") ].map { |p| File.basename p }
  end
  
  # returns true if this aip is in the workspace
  def in_here? aip
    File.exist? File.join(@dir, aip)
  end

end
