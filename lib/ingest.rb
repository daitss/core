require "digest/sha1"
require "aip_record"

module Ingest

  def ingest!
    
    begin

      # aip level stuff
      validate! unless validated?
      retrieve_provenance! unless provenance_retrieved?
      retrieve_rxp_provenance! unless rxp_provenance_retrieved?
      retrieve_representations! unless representations_retrieved?

      # file level stuff
      files.each { |f| f.process! }
      
      # storage stuff
      tarball = Tarball.new do |t|
        t.add File.join(id, "descriptor.xml"), xml
        
        files.each do |f| 
          tar_path = File.join name, 'files', f.path
          t.add tar_path, f.data
        end

      end

      # TODO put the copy at the silo
      copy_url = nil

      # make an aip
      aip = Aip.new
      aip.xml = describe!
      aip.needs_work = true
      aip.sha1 = Digest::SHA1.hexdigest tarball
      aip.size = tarball.size
      aip.url = copy_url

      unless aip.save
        raise "could not save aip"
      end

      # TODO clean it off the disk
    rescue Reject => e
      @tags['REJECT'] = message
    rescue => e
      @tags['SNAFU'] = message
    end
    
  end

end
