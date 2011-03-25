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

    # generates and retuns a reject report for the specified IEID
    def reject_report id
      @package = Package.first(:id => id)
      @message = @package.events.first(:name => "reject").notes

      template_by_name("reject_report").result binding
    end

  end
end


