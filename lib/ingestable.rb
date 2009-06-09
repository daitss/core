require 'validation'
require 'provenance'

module Ingestable

  def ingest!
    validate unless validated?
    retrieve_provenance unless provenance_retrieved?
    
    new_files = []

    files.each do |file|
      file.describe unless file.described?
      file.plan unless file.planned?
      new_files << file.transform if file.has_transformation?
    end

    new_files.each do |file|
      file.describe unless file.described?
      file.plan unless file.planned?
    end

    #aip.store
    #aip.flush_files
  end

  def store
  end

  def flush_files
  end

end
