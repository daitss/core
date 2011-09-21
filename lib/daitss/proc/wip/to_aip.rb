require 'daitss/service/randystore'

module Daitss

  class Wip

    def save_aip
      rs = nil
      aip = Aip.new :package => package, :copy => Copy.new
      add_substep('make aip', 'aip attributes') { aip.attributes = aip_attrs }

      # parse the aip descriptor and build the preservation records
      aipInPremis = AIPInPremis.new
      add_substep('make aip', 'parse aip') {
         aipInPremis.process aip.package, LibXML::XML::Document.string(aip.xml)
      }
            
      # write the tarball to storage
      add_substep('make aip', 'storage write') { 
        rs = RandyStore.reserve id
        aip.copy.attributes = rs.put_file tarball_file 
      }
      
      begin
        # save the aip descriptor and all preservation records
        add_substep('make aip', 'db save') {
          Aip.transaction do
            aip.raise_on_save_failure = true
            aip.save
            aipInPremis.toDB
          end
        }
      rescue
        #if db save fails, delete the new aip from storage.
        rs.delete
        raise
      end

      aip
    end

    def update_aip
      rs = nil
      old_rs = nil
      aip = package.aip
      add_substep('make aip', 'aip attributes') { aip.attributes = aip_attrs }

      # parse the aip descriptor and build the preservation records
      aipInPremis = AIPInPremis.new
      add_substep('make aip', 'parse aip') {
         aipInPremis.process aip.package, LibXML::XML::Document.string(aip.xml)
      }
      
      # write the tarball to storage
      add_substep('make aip', 'storage write') { 
        rs = RandyStore.reserve id
        old_rs = RandyStore.new id, aip.copy.url.to_s      
        aip.copy.attributes = rs.put_file tarball_file
      }
      
      begin
        Aip.transaction do
          # save the aip descriptor and all preservation records
          add_substep('make aip', 'db save') {
            aip.raise_on_save_failure = true
            aip.save
            aipInPremis.toDB
          }
          # delete the old aip from storage
          add_substep('make aip', 'delete old aip') {old_rs.delete}
        end
      rescue
        rs.delete
        raise
      end

      aip
    end

    def withdraw_aip
      aip = package.aip
      add_substep('make aip', 'aip attributes') { aip.attributes = aip_attrs }

      old_rs = RandyStore.new id, aip.copy.url.to_s

      # parse the tombstone' aip descriptor and build the preservation records
      aipInPremis = AIPInPremis.new
      add_substep('make aip', 'parse aip') {
        aipInPremis.process aip.package, LibXML::XML::Document.string(aip.xml)
      }

      aip.copy.destroy
      # save the 'tombstone' aip descriptor and all preservation records
      add_substep('make aip', 'db save') {
        aip.raise_on_save_failure = true
        aip.save
        aipInPremis.toDB
      }
      
      # delete the aip from storage
      add_substep('make aip', 'delete aip') { old_rs.delete }

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
