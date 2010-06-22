require 'wip/from_sip'
require 'tempdir'

require 'daitss2'

class ArchiveExtractionError < StandardError; end
class DescriptorNotFoundError < StandardError; end

class Sip

  # extracts sip file from zip, tar, or gzip file, creates record in sip table, and returns a Sip object

  def Sip.from_archive path_to_archive, ieid, package_name

    # write record to sip table
    sip = SubmittedSip.new
    sip.attributes = { :package_name => package_name,
                       :ieid => ieid }
    sip.save!

    # detect archive type
    type = detect_archive_type path_to_archive

    # extract from archive
    sip_path = extract_archive path_to_archive, type, package_name
    update_sip_record sip, sip_path

    # create sip object
    begin
      return Sip.new sip_path
    rescue Errno::ENOENT
      raise DescriptorNotFoundError
    end
  end

  private

  def Sip.update_sip_record sip_record, sip_path
    sip_contents = Dir.glob("#{sip_path}/**/*")

    files_in_sip = sip_contents.reject {|path| File.file?(path) == false}
    package_size = sip_contents.inject(0) {|sum, path| sum + File.stat(path).size}

    sip_record.attributes = { 
      :package_size => package_size,
      :number_of_datafiles => files_in_sip.length
       }

    sip_record.save!
  end

  def Sip.detect_archive_type path_to_archive
    file_string = `file #{path_to_archive}`

    if file_string =~ /tar/i
      :tar
    elsif file_string =~ /zip/i
      :zip 
    else
      raise ArchiveExtractionError, "Can't determine archive type"
    end
  end

  def Sip.extract_archive path_to_archive, type, package_name

    unarchive_destination = Tempdir.new
    sip_path = File.join unarchive_destination.path, package_name

    case type

    when :tar
      tar_command = `which tar`.chomp
      raise ArchiveExtractionError, "tar utility not found on this system!" if tar_command =~ /not found/
      command = "#{tar_command} -xf #{path_to_archive} -C #{unarchive_destination.path} 2>&1"

    when :zip
      zip_command = `which unzip`.chomp
      raise ArchiveExtractionError, "unzip utility not found on this system!" if zip_command =~ /not found/
      command = "#{zip_command} -o #{path_to_archive} -d #{unarchive_destination.path} 2>&1"
    end

    output = `#{command}`
    raise ArchiveExtractionError, "Extraction utility returned non-zero exit status: #{output}" unless $?.exitstatus == 0
    raise ArchiveExtractionError, "SIP not in #{package_name} subdirectory" unless File.directory? sip_path

   return sip_path
  end
end
