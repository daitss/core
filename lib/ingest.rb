require "aip_record"

module Ingest

  def ingest!
    
    begin
      validate! unless validated?
      retrieve_provenance! unless provenance_retrieved?
      retrieve_rxp_provenance! unless rxp_provenance_retrieved?
      retrieve_representations! unless representations_retrieved?
      files.each { |f| f.process! }
      store! unless stored?
      save_to_db!
    rescue Reject => e
      write_reject_info e
    rescue => e
      write_snafu_info e
    end
    
  end

  def rejected?
    File.exist? reject_tag_file
  end

  def snafu?
    File.exist? snafu_tag_file
  end

  def save_to_db!
    xml_blob = open(descriptor_file) { |io| io.read }    
    air = AipRecord.new :name => File.basename(path), :xml => xml_blob, :needs_work => true
    air.save
  end
  
end
