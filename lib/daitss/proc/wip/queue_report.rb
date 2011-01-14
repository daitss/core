module Daitss
  class Wip
    def queue_report
      p = self.package
      r = ReportDelivery.new :package => p
      p.project.account.report_email.length > 0 ? r.mechanism = :email : r.mechanism = :ftp 

      r.save
    end
  end
end
