require 'xml'
require 'db/daitss2.rb'

module AIPInPremis
  def processPremis premis
    @df = Datafile.new
    @df.fromPremis premis
   
    # process all matched formats
    list = premis.find("premis:objectCharacteristics/premis:format", NAMESPACES)
    firstNode = true
    list.each do |node|
      format = Format.new
      format.fromPremis node
      # determine if this format is already at our format table
      record = Format.first(:format_name => format.format_name)
      unless (record.nil?)
        record = format
      end
      
      fileformat = FileFormat.new
      fileformat.datafile_id = @df.id
      fileformat.format_id = record.formatName
      # first format element is designated for the file format.  Subsequent format elements are used for format profiles
      if (firstNode)
        fileformat.setPrimary
        firstNode = false
      else
        fileformat.setSecondary
      end
    end
    
    #TODO need storage data model
    @mdtype = premis.find_first("premis:objectCharacteristics/premis:fixity/premis:messageDigestAlgorithm", NAMESPACES).content
    @mdvalue = premis.find_first("premis:objectCharacteristics/premis:fixity/premis:messageDigest", NAMESPACES).content
  end

  def toDB
    df = Datafile.new
    df.id = @id
    df.size = @fsize.to_i
    df.create_date = @create_date if @create_date
    df.creator_prog = @creator_prog if @creator_prog
    df.original_path = @originalName if @originalName

    df.save
  end
end