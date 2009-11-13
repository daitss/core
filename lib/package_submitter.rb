class PackageSubmitter

  # creates a new aip in the workspace from SIP in zip file located at path_to_zip_file
  # returns the newly minted IEID of the created AIP
  
  def self.create_aip_from_zip path_to_zip_file
    check_workspace
    ieid = generate_ieid

    # unzip or untar to temp dir
    # call Aip.make_from_sip
    # add submission event to polydescriptor 
  end

  # creates a new aip in the workspace from SIP in tar file located at path_to_tar_file
  # returns the newly minted IEID of the created AIP

  def self.create_aip_from_tar path_to_tar_file
    check_workspace
    ieid = generate_ieid

    # call Aip.make_from_sip
    # add submission event to polydescriptor 
  end

  private 

  # raises exception if DAITSS_WORKSPACE environment variable is not set to a valid directory on the filesystem

  def self.check_workspace
    raise "DAITSS_WORKSPACE is not set to a valid directory." unless File.directory? ENV["DAITSS_WORKSPACE"]
  end

  # generates a unique IEID
  # TODO: eventually, this should be taken from the submission history, which will be a database
  def self.generate_ieid
    ieid_history_filepath = File.join(File.dirname(__FILE__), ".ieid_history")

    new_ieid = File.open(ieid_history_filepath, "a+") do |status_file|
      status_file.rewind
      
      while not status_file.eof?
        last_ieid = status_file.gets
      end

      if last_ieid == nil
        ieid = 0
      else
        ieid = last_ieid.to_i + 1
      end

      status_file.puts ieid
      ieid
    end

    return new_ieid 
  end

  def self.unzip_sip 
  end

  def self.unzip_tar
  end

  def self.create_submission_event
  end
end
