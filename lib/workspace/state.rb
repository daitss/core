class State
 
  include Enumerable

  def initialize path
    @path = path
  end

  def empty?
    jobs.empty?
  end

  def append aip, job
    FileUtils::touch job_file(aip, job)
  end

  def write new_jobs
    clear!
    new_jobs.each { |aip, job| append aip, job }
  end

  def each

    jobs.each do |aip, job| 

      if running? job
        yield [aip, job]
      else
        clear! job_file(aip, job)
      end

    end

  end


private

  def files
    Dir[File.join @path, "*"]
  end

  SEP = ' '

  def jobs
    files.map { |f| File.basename(f).split(SEP) }
  end

  def job_file aip, job
    File.join @path, [aip, job].join(SEP)
  end

  def clear! f=nil
    FileUtils::rm f ? f : files
  end

  def running? job

    begin
      Process.kill(0, job.to_i)
      true
    rescue Errno::ESRCH
      false
    end

  end

end
