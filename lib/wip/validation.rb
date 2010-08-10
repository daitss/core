require 'wip'
require 'wip/sip_descriptor'
require 'datafile/checksum'
require 'datafile/name_validation'

require 'daitss2'

class Wip

  # returns true if package account is present in the database, false otherwise
  def package_account_valid?
    Account.first(:code => metadata["dmd-account"]) != nil
  end

  # returns true if the package account matches account of submitter, false otherwise
  def package_account_matches_agent? agent
    agent.account.code == metadata["dmd-account"] or agent.type == Operator
  end

  # returns true if package project is present in database, false otherwise
  def package_project_valid?
    Project.first(:code => metadata["dmd-project"], :account => {:code => metadata["dmd-account"]}) != nil
  end

  # returns true if there is at least one non-descriptor file present that is described in the SIP descriptor, false otherwise
  def content_file_exists?
    return false unless described_datafiles.length > 0
    present_described_datafiles = []

    described_datafiles.each do |datafile|
      if File.exists? datafile.datapath
        present_described_datafiles << datafile
      end
    end

    present_described_datafiles.length > 0
  end

  # returns true if all described datafiles match checksums in sip descriptor
  # a file will not be checked if:
  #   no checksum is provided for that file
  #   the checksum type provided is not MD5 or SHA1
  #   the checksum type is not provided and has length other than 32 or 40
  # if the checksum type not provided and has length 32, it will be assumed to be an MD5 checksum 
  # if the checksum type not provided and has length 40, it will be assumed to be a SHA1 checksum 
  # writes any failures found to metadata file called checksum_failures
  def content_file_checksums_match?
    checksum_failures = ""
    described_datafiles.each do |datafile|
      info = datafile.checksum_info

      if File.exists?(datafile.datapath) == false
        checksum_failures << "#{datafile['sip-path']} - missing; " 
      elsif info[0] != info[1]
        checksum_failures << "#{datafile['sip-path']} - expected: #{info[0]} computed: #{info[1]}; " 
      else
        next
      end
    end

    if checksum_failures.length > 0
      metadata["checksum_failures"] = checksum_failures
      return false
    else
      return true
    end
  end

  # returns true if:
  #   package name has no more than 32 chars
  #   package name does not start with a dot
  #   package name does not contain spaces or quote characters
  # otherwise, returns false
  def package_name_valid?
    return false if metadata["sip-name"] =~ /^\./
    return false if metadata["sip-name"] =~ /"/
    return false if metadata["sip-name"] =~ /'/
    return false if metadata["sip-name"] =~ / /
    return false if metadata["sip-name"].length > 32

    true
  end

  def content_files_have_valid_names?
    original_datafiles.each do |datafile|
      return false unless datafile.original_name_valid?
    end

    true
  end
end
