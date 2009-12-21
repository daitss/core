require 'aip'
require 'service/validate'

class Reject < StandardError; end

module Ingest

  include Service::Validate

  def ingest!
    
    begin

      # aip level stuff
      validate! unless validated?
      retrieve_dmd! unless dmd_retrieved?
      retrieve_provenance! unless provenance_retrieved?
      retrieve_rxp_provenance! unless rxp_provenance_retrieved?
      retrieve_representations! unless representations_retrieved?

      # describe all files
      datafiles.each { |f| f.describe! unless f.described? }

      # determine existing original_rep and current_rep
      original_rep = datafiles if original_rep.empty?
      current_rep = original_rep if current_rep.empty?

      # new reps
      new_current_rep = current_rep.map { |df| df.migrate || df }
      new_normalized_rep = original_rep.map { |df| df.normalize || df }
    
      # persist the representations
      current_rep = new_current_rep unless new_current_rep.empty?
      normalized_rep = new_normalized_rep unless new_normalized_rep.empty?

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
