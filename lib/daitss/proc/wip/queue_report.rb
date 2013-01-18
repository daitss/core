module Daitss
  class Wip
    def queue_report type
      p = self.package
      r = ReportDelivery.new :package => p,  :type => type
      (p.project.account.report_email == nil or p.project.account.report_email.length == 0) ? r.mechanism = :ftp : r.mechanism = :email

      r.save
    end
  end
end
