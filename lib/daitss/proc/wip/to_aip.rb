require 'daitss/service/storagemaster'

module Daitss

  class Wip

    def save_aip
      rs = nil
      aip = Aip.new :package => package, :copy => Copy.new

      add_substep('make aip', 'aip attributes') { aip.attributes = aip_attrs }

      # parse the aip descriptor and build the preservation records
      aipInPremis = AIPInPremis.new
      add_substep('make aip', 'parse aip') {
        Datyl::Logger.info "Parsing AIP descriptor for #{id}"
        aipInPremis.process aip.package, LibXML::XML::Document.string(aip.xml)
      }
            
      # write the tarball to storage
      add_substep('make aip', 'storage write') { 
        Datyl::Logger.info "Reserving storage for #{id}"
        rs = StorageMaster.reserve id
        Datyl::Logger.info "Writing AIP for #{id} to storage"
        aip.copy.attributes = rs.put_file tarball_file 
      }

 
      begin
        # save the aip descriptor and all preservation records
        add_substep('make aip', 'db save') {
          Aip.transaction do
            Datyl::Logger.info "Writing AIP records for #{id} to database"
            aip.toDB
            aipInPremis.toDB
          end
        }
      rescue => e
        #if db save fails, delete the new aip from storage.
        Datyl::Logger.err "Caught exception #{e.class}: '#{e.message}' updating database for #{id}, rolling back AIP on storage; backtrace follows"
         e.backtrace.each { |line| Datyl::Logger.err line }        
        rs.delete
        raise
      end

      aip
    end

    def update_aip
      rs = nil
      aip = package.aip

      add_substep('make aip', 'aip attributes') { aip.attributes = aip_attrs }

      # parse the aip descriptor and build the preservation records
      aipInPremis = AIPInPremis.new
      add_substep('make aip', 'parse aip') {
         Datyl::Logger.info "Parsing AIP descriptor for #{id}"  
         aipInPremis.process aip.package, LibXML::XML::Document.string(aip.xml)
      }
      
      # write the tarball to storage
      add_substep('make aip', 'storage write') { 
        Datyl::Logger.info "Reserving storage for updated AIP for #{id}"
        rs = StorageMaster.reserve id
            
        metadata['old-copy-url'] = aip.copy.url.to_s

        Datyl::Logger.info "Writing updated AIP for #{id} to storage" 
        aip.copy.attributes = rs.put_file tarball_file
      }
      
      begin
        Aip.transaction do
          # save the aip descriptor and all preservation records
          add_substep('make aip', 'db save') {
            Datyl::Logger.info "Updating AIP in database for #{id}"    
            aip.toDB
            aipInPremis.toDB
          }
          
        end
      rescue => e
         Datyl::Logger.err "Caught exception #{e.class}: '#{e.message}' updating database for #{id}, rolling back AIP on storage; backtrace follows"
         e.backtrace.each { |line| Datyl::Logger.err line }
         rs.delete
        raise
      end

      aip
    end

    def delete_old_aip
      old_copy = StorageMaster.new id, metadata['old-copy-url']

      # attempt to delete old AIP, log error if failure
      begin
        Datyl::Logger.info "Deleting old AIP for #{id} from storage"
        old_copy.delete
      rescue => e
        # log orphan
        Datyl::Logger.err "Caught exception #{e.class}: '#{e.message}' deleting old copy of #{id} after AIP update; backtrace follows"
        e.backtrace.each { |line| Datyl::Logger.err line }
        raise
      end
    end

    def withdraw_aip
      aip = package.aip
      add_substep('withdraw aip', 'aip attributes') { aip.attributes = aip_attrs }

      # parse the tombstone' aip descriptor and build the preservation records
      aipInPremis = AIPInPremis.new
      add_substep('withdraw aip', 'parse aip') {
        Datyl::Logger.info "Parsing AIP descriptor for #{id}"
        aipInPremis.process aip.package, LibXML::XML::Document.string(aip.xml)
      }

      # save the 'tombstone' aip descriptor and all preservation records
      add_substep('withdraw aip', 'db save') {
        Datyl::Logger.info "Updating AIP for withdrawal in database for #{id}"      
        aip.toDB
        aipInPremis.toDB
      }

      if aip.copy
        old_rs = StorageMaster.new id, aip.copy.url.to_s

        # delete the aip from storage
        add_substep('withdraw aip', 'delete aip') { 
          Datyl::Logger.info "Deleting AIP for #{id} from storage"
          old_rs.delete 
          aip.copy.destroy
        }
      end

      aip
    end

    private

    def aip_attrs
      {
        :xml => load_aip_descriptor,
        :xml_errata => load_aip_descriptor_errata,
        :datafile_count => represented_datafiles.size
      }
    end

  end

end
