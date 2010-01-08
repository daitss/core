require 'aip'
require 'wip'
require 'service/validate'
require 'service/describe'

module Ingest


  def ingest!
    
    # TODO all milestones are "since last ingest" if a previous ingest exist
    # TODO all incoming provenance is imported at the end
    # TODO all obsolete files need their object to persist

    begin
      validate! unless validated?
      datafiles.each { |f| f.describe! unless f.described? }

      # determine existing original_rep and current_rep
      (original_rep = datafiles if original_rep.empty?) unless original_rep_set?
      (current_rep = original_rep if current_rep.empty?) unless current_rep_set?

      # new reps
      new_current_rep = current_rep.map { |df| df.migrate || df } # unless we already migrated this file, cleanup entire new file for damage control
      new_normalized_rep = original_rep.map { |df| df.normalize || df }
    
      # persist the representations
      (current_rep = new_current_rep unless new_current_rep.empty?) unless current_rep_updated?
      (normalized_rep = new_normalized_rep unless new_normalized_rep.empty?) unless normalized_rep_updated?

      # clean out
      represented_files = (original_rep + current_rep + normalized_rep).uniq
      unrepresented_files = datafiles - represented_files
      unrepresented_files.each { |f| f.prove_obsolete! unless f.proven_obsolete? }

      prove_ingest! unless ingest_proven?

      make_aip! represented_files
    rescue Reject => e
      tags['REJECT'] = e.message
    rescue => e
      tags['SNAFU'] = ( [e.message] + e.backtrace ).join "\n"
    end
    
  end

  private

  def make_aip! files

    aip = Aip.new
    aip.id = uri
    aip.xml = describe!
    aip.needs_work = true
    aip.url = "#{CONFIG['storage-url']}/#{id}"

    aip.tarball = Tarball.new do |t|
      t.add File.join(id, "descriptor.xml"), aip.xml

      files.each do |f| 
        tar_path = File.join id, 'files', f['sip-path']
        t.add tar_path, f.data
      end

    end

    unless aip.save 
      raise "could not save aip"
    end

  end

end
