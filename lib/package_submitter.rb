class PackageSubmitter

  # creates a new aip in the workspace from SIP in zip file located at path_to_zip_file
  # returns the newly minted IEID of the created AIP
  
  def self.create_aip_from_zip path_to_zip_file
    check_workspace
    # generate an ieid
    # unzip or untar to temp dir
    # call Aip.make_from_sip
    # add submission event to polydescriptor 
  end

  # creates a new aip in the workspace from SIP in tar file located at path_to_tar_file
  # returns the newly minted IEID of the created AIP

  def self.create_aip_from_tar path_to_tar_file
    check_workspace
    # generate an ieid
    # unzip or untar to temp dir
    # call Aip.make_from_sip
    # add submission event to polydescriptor 
  end

  private 

  def self.check_workspace
    raise "DAITSS_WORKSPACE is not set to a valid directory." unless File.directory? ENV["DAITSS_WORKSPACE"]
  end

  def self.generate_ieid
  end

  def self.unzip_sip 
  end

  def self.unzip_tar
  end

  def self.create_submission_event
  end
end
