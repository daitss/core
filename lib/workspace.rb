class Workspace

  # make a new worksapce out of a directory
  def initialize dir
    @dir = dir
  end

  # start ingests for a package (:all for any ingestable package)
  def start target, config_file

    wips = if target == :all
             pending + tagged_with("STOP")
           else
             wip = Wip.new File.join(@dir, target)
             raise "#{wip} is not in the workspace" unless in_here? wip
             raise "#{wip} is ingesting" if wip.tags['INGEST']
             raise "#{wip} is SNAFU" if wip.tags['SNAFU']
             raise "#{wip} is REJECTED" if wip.tags['REJECT'] 
             [wip]
           end

    wips.each do |wip|
      wip.tags.delete 'STOP'
      path = File.join @dir, wip
      pid = fork { exec "WORKSPACE=#{@dir}; ruby -Ilib bin/ingest #{config_file} #{path}" }
      wip.tags['INGEST'] = pid
    end

  end

  # stops ingests for a package (:all for any ingesting package)
  def stop target

    # don't stop something that is not processing
    to_stop = if target == :all
                tagged_with("INGEST")
              else
                wip = Wip.new File.join(@dir, target)
                raise "#{wip} is not ingesting" unless wip.has_key? 'INGEST' 
                [wip]
              end

    to_stop.each do |wip|

      pid = wip.tags['INGEST']

      begin
        Process.kill "INT", pid.to_i
      rescue Errno::ESRCH
        # OK if its done
      ensure
        wip.tags.delete 'INGEST'
        wip.tags['STOP'] = nil
      end
      
    end

  end

  def pending

    in_here.reject do |wip|
      %w(INGEST REJECT SNAFU STOP).any? { |tag| wip.tags.has_key? tag }
    end

  end

  def tagged_with tag
    in_here.select { |wip| wip.tags.has_key? tag }
  end

  def all_with_status

    in_here.map do |wip|
      state = "PENDING"
      state = "INGEST" if wip.has_key? 'INGEST'
      state = "STOP" if wip.has_key? 'STOP'
      state = "REJECT" if wip.has_key? 'REJECT'
      state = "SNAFU" if wip.has_key? 'SNAFU'
      "#{File.basename wip} #{state}"
    end

  end

  def stash wip, destination
    raise "#{wip} is ingesting" if wip.has_key? 'INGEST'
    FileUtils::mv wip.path, File.join(destination, File.basename(wip.path))
  end

  def unsnafu target

    if target == :all
      tagged_with('SNAFU').each { |wip| wip.tags.delete 'SNAFU' }
    else
      wip = Wip.new File.join(@dir, target)
      raise "#{target} is not SNAFU" unless wip.has_key?('SNAFU')
      wip.tags.delete 'SNAFU'
    end

  end

  private
  
  # returns all wips paths in the workspace
  def in_here
    Dir[ File.join(@dir, "*") ].map { |path| Wip path }
  end
  
  # returns true if this wip is in the workspace
  def in_here? wip
    File.exist? File.join(@dir, File.basename(wip.path))
  end

end
