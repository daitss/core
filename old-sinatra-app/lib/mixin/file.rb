class File

  def File.lock f, options={}
    fd = open f

    if options[:shared]
      fd.flock LOCK_SH
    else
      fd.flock LOCK_EX
    end

    r = yield
    fd.flock(LOCK_UN)
    fd.close
    r
  end

end
