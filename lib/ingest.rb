module Ingest

  def ingest!
    validate unless validated?
    retrieve_provenance unless provenance_retrieved?
    
    files.each do |file|
      file.describe unless file.described?
      file.plan unless file.planned?
      
      file.transformations.each do |t|
        t.perform!
        
        t.data do |io, fname| 
          new_file = add_file io, fname
          new_file.add_md :tech, t.metadata
          new_file.describe unless file.described?
        end
        
      end
      
    end

    store
    flush_files
  end

  def store
    # TODO
  end

  def flush_files
    # TODO
  end

end
