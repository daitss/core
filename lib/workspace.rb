module Workspace
  
  # the file that stores the state
  def state_file
    File.join ENV['DAITSS_WORKSPACE'], ".boss"
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
  def in_workspace
    Dir[File.join(ENV['DAITSS_WORKSPACE'], "*")]
  end

  # returns all aips tagged with tag
  def tagged_packages tag
    in_workspace.select { |aip| File.exists? File.join(aip, tag)  }
  end
  
  # returns ingesting aips
  def ingesting
    read_state.map { |aip, pid| aip }
  end

  def ingesting? aip
    ingesting.include? aip
  end
  
end
