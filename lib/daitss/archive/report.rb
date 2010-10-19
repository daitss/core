require 'daitss/archive'
require 'daitss/proc/template'

module Daitss

  class Archive
    
    # generates and returns an ingest report for the specified IEID 
    def ingest_report id
      @intentity_record = Intentity.first(:id => uri_prefix + id)
      @package = Package.first(:id => id)

      if not @intentity_record
        raise "There is no record that #{id} was ingested."
      end

      template_by_name("ingest_report").result binding
    end
  end
end


