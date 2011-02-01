require 'daitss/service/randystore'

module Daitss

  class Wip

    def save_aip
      aip = Aip.new :package => package, :copy => Copy.new
      aip.attributes = aip_attrs
      rs = RandyStore.reserve id
      aip.copy.attributes = rs.put_file tarball_file

      begin
        aip.save_and_populate
      rescue
        rs.delete
        raise
      end

      aip
    end

    def update_aip
      aip = package.aip
      aip.attributes = aip_attrs
      rs = RandyStore.reserve id
      old_rs = RandyStore.new id, aip.copy.url.to_s
      aip.copy.attributes = rs.put_file tarball_file

      begin
        aip.save_and_populate
        old_rs.delete
      rescue
        rs.delete
        raise
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
