require 'daitss/service/randystore'

module Daitss

  class Wip

    def save_aip
      aip = Aip.new :package => package, :copy => Copy.new
      aip.attributes = aip_attrs
      rs = RandyStore.reserve id
      aip.copy.attributes = rs.put_file tarball_file

      unless aip.save_and_populate
        rs.delete
        raise 'could not save aip'
      end

      aip
    end

    def update_aip
      aip = package.aip
      aip.attributes = aip_attrs
      rs = RandyStore.reserve id
      old_rs = RandyStore.new id, aip.copy.url.to_s
      aip.copy.attributes = rs.put_file tarball_file

      if aip.save_and_populate
        old_rs.delete
      else
        rs.delete
        raise 'could not save aip'
      end

      aip
    end

    private

    def aip_attrs
      {
        :xml => load_aip_descriptor,
        :datafile_count => represented_datafiles.size
      }
    end

  end

end
