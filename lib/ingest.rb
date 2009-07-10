module Ingest

  def ingest!
    
    begin
      validate! unless validated?
      retrieve_provenance! unless provenance_retrieved?
      retrieve_rxp_provenance! unless rxp_provenance_retrieved?
      retrieve_representations! unless representations_retrieved?
      files.each { |f| f.process! }
      store! unless stored?
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

end
