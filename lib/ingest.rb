require 'aip'

module Ingest

  def ingest!
    
    begin

      # aip level stuff
      validate! unless validated?
      retrieve_dmd! unless dmd_retrieved?
      retrieve_provenance! unless provenance_retrieved?
      retrieve_rxp_provenance! unless rxp_provenance_retrieved?
      retrieve_representations! unless representations_retrieved?

      # file level stuff
      original_representation ||= Representation.new *files
      new_current_representation = current_representation || Representation.new *files
      new_normalized_representation = Representation.new
      files.each { |f| f.describe! unless f.described? }

      original_representation.each do |f| 

        f.normalize do |new_data|
          new_normalized_representation << new_file
          new_file.describe!
          new_file.prove_normalization! unless new_file.normalization_proved?
        end

      end

      current_representation.each do |f| 

        f.migrate do |new_data|
          new_current_representation << new_file
          new_file.describe!
          new_file.prove_migration unless new_file.migration_proved?
        end

      end
      
      current_representation = new_current_representation unless new_current_representation.empty?
      normalized_representation = new_normalized_representation unless new_normalized_representation.empty?
      unrepresented_files.each { |f| prove_file_obsolete f.prove_obsolete! unless f.proven_obsolete? }

      prove_ingest! unless ingest_proven?
      make_aip!
    rescue Reject => e
      @tags['REJECT'] = message
    rescue => e
      @tags['SNAFU'] = message
    end
    
  end

  private

  def make_aip!

    aip = Aip.new
    aip.xml = describe!
    aip.needs_work = true
    aip.url = "#{CONFIG['storage-url']}/#{id}"

    aip.tarball = Tarball.new do |t|
      t.add File.join(id, "descriptor.xml"), xml

      represented_files.each do |f| 
        tar_path = File.join name, 'files', f.path
        t.add tar_path, f.data
      end

    end

    aip.save || raise "could not save aip"
  end

end
