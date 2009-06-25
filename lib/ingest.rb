module Ingest

  def ingest!
    
    begin
      validate unless validated?
      retrieve_provenance unless provenance_retrieved?
      retrieve_rxp_provenance unless rxp_provenance_retrieved?
      retrieve_representations unless representations_retrieved?
      files.each { |f| f.process! }
      store
      save_to_db
      flush_files
    rescue Reject => e
      write_reject_info e
    rescue => e
      write_snafu_info e
    end
    
  end

  def store
    # TODO
  end
  
  def save_to_db
    # TODO
  end

  def flush_files
    # TODO
  end

  def rejected?
    File.exist? reject_tag_file
  end

  def snafu?
    File.exist? snafu_tag_file
  end

end
