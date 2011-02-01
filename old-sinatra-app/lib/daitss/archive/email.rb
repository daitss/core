require 'daitss/archive'
require 'daitss/archive/report'
require 'net/smtp'

module Daitss

  class Archive
    def email_report package
      account = package.project.account

      marker = rand(1000000000000)

msg = <<EOF
From: DAITSS <do_not_reply@fcla.edu>
To: DAITSS Account #{account.id} <#{account.report_email}>
Subject: Ingest Report for #{package.id}
Date: #{Time.now.to_s}
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: 7bit
Content-Type: multipart/mixed; boundary=#{marker}
--#{marker}

Content-Type: text/plain
Content-Transfer-Encoding: 7bit

Ingest report for package #{package.id}
--#{marker}

Content-Type: multipart/mixed; name="#{package.id}.xml"
Content-Transfer-Encoding: 7bit

#{ingest_report package.id}
--#{marker}--
EOF

      Net::SMTP.start("localhost") do |smtp|
        smtp.send_message msg, 'do_not_reply@fcla.edu', account.report_email
      end
    end
  end
end
 
