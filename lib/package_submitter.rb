require 'fileutils'
require 'aip'
require 'pp'

class PackageSubmitter

  # creates a new aip in the workspace from SIP in zip file located at path_to_zip_file
  # returns the newly minted IEID of the created AIP
  
  def self.create_aip_from_zip path_to_zip_file, package_name
    check_workspace
    ieid = generate_ieid
    unzip_sip ieid, path_to_zip_file, package_name

    aip_path = File.join(ENV["DAITSS_WORKSPACE"], "aip-#{ieid}")
    sip_path = File.join(ENV["DAITSS_WORKSPACE"], ".submit", package_name)

    Aip.make_from_sip aip_path, sip_path

    # add submission event to polydescriptor 
    return ieid
  end

  # creates a new aip in the workspace from SIP in tar file located at path_to_tar_file
  # returns the newly minted IEID of the created AIP

  def self.create_aip_from_tar path_to_tar_file, package_name
    check_workspace
    ieid = generate_ieid
    untar_sip ieid, path_to_tar_file, package_name

    aip_path = File.join(ENV["DAITSS_WORKSPACE"], "aip-#{ieid}")
    sip_path = File.join(ENV["DAITSS_WORKSPACE"], ".submit", package_name)

    Aip.make_from_sip aip_path, sip_path

    # add submission event to polydescriptor 
    
    return ieid
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

  # unzips specified zip file to $DAITSS_WORKSPACE/.submit/aip-IEID/

  def self.unzip_sip ieid, path_to_zip_file, package_name
    create_submit_dir unless File.directory? File.join(ENV["DAITSS_WORKSPACE"], ".submit")

    zip_command = `which unzip`.chomp
    destination = File.join ENV["DAITSS_WORKSPACE"], ".submit", package_name

    raise "unzip utility not found on this system!" if zip_command =~ /not found/

    output = `#{zip_command} #{path_to_zip_file} -d #{destination}`
    contents = Dir.entries destination

    # if package was zipped in a single directory, move files out
    if contents.length == 3 and File.directory? File.join(destination, contents[2])
      FileUtils.mv Dir.glob(File.join(destination, "#{contents[2]}/*")), destination
      FileUtils.rm_rf File.join(destination, contents[2])
    end

    raise "unzip utility exited with non-zero status: #{output}" if $?.exitstatus != 0 
  end

  # unzips specified tar file to $DAITSS_WORKSPACE/.submit/aip-IEID/

  def self.untar_sip ieid, path_to_tar_file, package_name
    create_submit_dir unless File.directory? File.join(ENV["DAITSS_WORKSPACE"], ".submit")

    tar_command = `which tar`.chomp
    destination = File.join ENV["DAITSS_WORKSPACE"], ".submit", package_name

    raise "tar utility not found on this system!" if tar_command =~ /not found/

    FileUtils.mkdir_p destination
    output = `#{tar_command} -xf #{path_to_tar_file} -C #{destination}`

    contents = Dir.entries destination

    # if package was zipped in a single directory, move files out
    if contents.length == 3 and File.directory? File.join(destination, contents[2])
      FileUtils.mv Dir.glob(File.join(destination, "#{contents[2]}/*")), destination
      FileUtils.rm_rf File.join(destination, contents[2])
    end

    raise "tar utility exited with non-zero status: #{output}" if $?.exitstatus != 0 
  end

  def self.create_submission_event
  end

  # creates a .submit directory under DAITSS_WORKSPACE

  def self.create_submit_dir
    FileUtils.mkdir_p File.join(ENV["DAITSS_WORKSPACE"], ".submit")
  end
end
