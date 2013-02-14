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

    def withdrawal_report id
      @package = Package.first(:id => id)
      @intentity_record = Intentity.first(:id => uri_prefix + id)

      if not @intentity_record
        raise "There is no record that #{id} was ingested."
      end

      template_by_name("withdraw_report").result binding
    end

    def refresh_report id
      @package = Package.first(:id => id)
      @intentity_record = @package.intentity

      if not @intentity_record
        raise "There is no record that #{id} was ingested."
      end

      template_by_name("refresh_report").result binding
    end
    
    # generates and returns an disseminate  report for the specified IEID 
    def disseminate_report id
      @intentity_record = Intentity.first(:id => uri_prefix + id)
      @package = Package.last(:id => id)

      if not @intentity_record
        raise "There is no record that #{id} was ingested."
      end

      template_by_name("disseminate_report").result binding
    end



  end
end


