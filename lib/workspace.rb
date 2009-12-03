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
             raise "#{aip} is ingesting" if File.exists? File.join(@dir, aip, "INGEST")
             raise "#{aip} is SNAFU" if File.exists? File.join(@dir, aip, "SNAFU")
             raise "#{aip} is REJECTED" if File.exists? File.join(@dir, aip, "REJECT")
             [aip]
           end

    aips.each do |aip|
      FileUtils::rm_rf File.join(@dir, aip, "STOP")
      path = File.join @dir, aip
      pid = fork { exec "ruby -Ilib bin/ingest -aip #{path} -config #{config_file}" }
      open(File.join(path, "INGEST"), "w") { |io| io.puts pid }
    end

  end

  # stops ingests for a package (:all for any ingesting package)
  def stop target

    # don't stop something that is not processing
    to_stop = if target == :all
                tagged_with("INGEST")
              else
                aip = target
                raise "#{aip} is not ingesting" unless File.file? File.join(@dir, aip, "INGEST")
                [aip]
              end

    to_stop.each do |aip|
      pid = open(File.join(@dir, aip, "INGEST")) { |io| io.readline.chomp }

      begin
        Process.kill "INT", pid.to_i
      rescue Errno::ESRCH
        # OK if its done
      ensure
        FileUtils::rm File.join(@dir, aip, "INGEST")
        FileUtils::touch File.join(@dir, aip, "STOP")
      end
      
    end

  end

  def pending

    in_here.reject do |aip|

      %w(INGEST REJECT SNAFU STOP).any? do |tag|
        File.exist? File.join(@dir, aip, tag)
      end

    end

  end

  def tagged_with tag
    in_here.select { |aip| File.exists? File.join(@dir, aip, tag) }
  end

  def all_with_status

    in_here.map do |aip|
      state = "pending"
      state = "ingesting" if File.file? File.join(@dir, aip, "INGEST")
      state = "STOP" if File.file? File.join(@dir, aip, "STOP")
      state = "REJECT" if File.file? File.join(@dir, aip, "REJECT")
      state = "SNAFU" if File.file? File.join(@dir, aip, "SNAFU")
      "#{File.basename aip} #{state}"
    end

  end

  def stash aip, destination
    raise "#{aip} is ingesting" if File.file? File.join(@dir, aip, "INGEST")
    FileUtils::mv File.join(@dir, aip), File.join(destination, aip)
  end

  def unsnafu aip
    raise "#{aip} is not SNAFU" if aip != :all and !File.exist? File.join(@dir, aip, "SNAFU")
    pattern = File.join @dir, (aip == :all ? "*" : aip), "SNAFU"
    Dir[pattern].each { |tag| FileUtils::rm tag }
  end

  private
  
  # returns all aips paths in the workspace
  def in_here
    Dir[ File.join(@dir, "*") ].map { |f| File.basename f }
  end
  
  # returns true if this aip is in the workspace
  def in_here? aip
    File.exist? File.join(@dir, aip)
  end

end
