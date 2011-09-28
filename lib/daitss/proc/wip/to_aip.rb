require 'daitss/service/randystore'

module Daitss

  class Wip

    def save_aip
      aip = Aip.new :package => package, :copy => Copy.new
      aip.attributes = aip_attrs

      Datyl::Logger.info "Reserving storage for #{id}"
      rs = RandyStore.reserve id

      Datyl::Logger.info "Writing AIP for #{id} to storage"
      aip.copy.attributes = rs.put_file tarball_file

      begin
        Datyl::Logger.info "Writing AIP for #{id} to database"
        aip.save_and_populate
      rescue => e

        Datyl::Logger.err "Caught exception #{e.class}: '#{e.message}' updating database, rolling back AIP on storage; backtrace follows"
        e.backtrace.each { |line| Datyl::Logger.err line }
        rs.delete
        raise
      end

      aip
    end

    def update_aip
      aip = package.aip
      aip.attributes = aip_attrs

      Datyl::Logger.info "Reserving storage for updated AIP for #{id}"
      rs = RandyStore.reserve id

      metadata['old-copy-url'] = aip.copy.url.to_s

      Datyl::Logger.info "Writing updated AIP for #{id} to storage"
      aip.copy.attributes = rs.put_file tarball_file

      begin
        Datyl::Logger.info "Updating AIP in database for #{id}"
        aip.save_and_populate
      rescue => e
        Datyl::Logger.err "Caught exception #{e.class}: '#{e.message}' updating database, rolling back AIP on storage; backtrace follows"
        e.backtrace.each { |line| Datyl::Logger.err line }

        rs.delete
        raise
      end

      aip
    end

    def delete_old_aip
      old_copy = RandyStore.new id, metadata['old-copy-url']

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
      aip.attributes = aip_attrs

      old_rs = RandyStore.new id, aip.copy.url.to_s

      aip.copy.destroy

      Datyl::Logger.info "Updating AIP for withdrawal in database for #{id}"
      aip.save_and_populate

      Datyl::Logger.info "Deleting AIP for #{id} from storage"
      old_rs.delete

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
