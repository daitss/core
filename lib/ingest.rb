module Ingest

  def ingest!
    validate unless validated?
    retrieve_provenance unless provenance_retrieved?
    retrieve_rxp_provenance unless rxp_provenance_retrieved?
    retrieve_representations unless representations_retrieved?
    
    files.each do |file|
      
      begin
        
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
          
      rescue => e
        t = template_by_name 'per_file_error'
        s = t.result binding
        error_doc = XML::Parser.string(s).parse
        file.add_md :digiprov, error_doc
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

  def rejected?
    File.exist? reject_tag_file
  end

  def snafu?
    File.exist? snafu_tag_file
  end

end
