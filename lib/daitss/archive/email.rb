require 'daitss/archive'
require 'daitss/archive/report'
require 'net/smtp'
require 'nokogiri'

module Daitss

  class Archive

    FROM = 'daitss@'+`hostname`.chomp

    def email_report package
      reply_to = archive.mailer_reply_to     
      account = package.project.account

      xslt  = Nokogiri::XSLT(File.read('public/daitss_report_xhtml.xsl'))
      doc = Nokogiri::XML ingest_report package.id 
      transform = xslt.transform(doc)
      html = transform.to_s
      marker = rand(1000000000000)


msg = <<EOF
From: DAITSS <#{FROM}>
Reply-To: #{reply_to}
To: DAITSS Account #{account.id} <#{account.report_email}>
Subject: Florida Digital Archive Report - Ingest of package #{package.sip.name}, IEID: #{package.id}
Date: #{Time.now.to_s}
Content-Type: multipart/mixed; boundary="#{marker}"

--#{marker}
Content-Type: text/plain

Ingest of package #{package.sip.name}, IEID: #{package.id}
--#{marker}
Content-Type: text/html; name="#{package.id}_ingest_report.html"

#{html}                  

--#{marker}--


EOF

    email msg,FROM,account.report_email
    end

    def email_reject_report package
      reply_to = archive.mailer_reply_to    
      account = package.project.account

      marker = rand(1000000000000)

msg = <<EOF
From: DAITSS <#{FROM}>
Reply-To: #{reply_to}
To: DAITSS Account #{account.id} <#{account.report_email}>
Subject: Florida Digital Archive Report - Reject of package #{package.sip.name}, IEID: #{package.id}
Date: #{Time.now.to_s}
Content-Type: multipart/mixed; boundary="#{marker}"

--#{marker}
Content-Type: text/plain

#{package.events.first(:name => "reject").notes}
--#{marker}
Content-Type: text/xml; name="#{package.id}.error.xml"

#{reject_report package.id}

--#{marker}--
EOF
    email msg,FROM,account.report_email
    end


    def email_dissemination_report package
      reply_to = archive.mailer_reply_to     
      account = package.project.account
      xslt  = Nokogiri::XSLT(File.read('public/daitss_report_xhtml.xsl'))
      doc = Nokogiri::XML disseminate_report package.id 
      transform = xslt.transform(doc)
      html = transform.to_s

      marker = rand(1000000000000)

msg = <<EOF
From: DAITSS <#{FROM}>
Reply-To: #{reply_to}
To: DAITSS Account #{account.id} <#{account.report_email}>
Subject: Florida Digital Archive Report - Dissemination of package #{package.sip.name}, IEID: #{package.id}
Date: #{Time.now.to_s}
Content-Type: multipart/mixed; boundary="#{marker}"

--#{marker}
Content-Type: text/plain

Dissemination of package #{package.sip.name}, IEID: #{package.id}
Dissemination request note: #{package.events.last(:name => "disseminate request placed").notes}
 
--#{marker}
Content-Type: text/html; name="#{package.id}_disseminate_report.html"

#{html}                  

--#{marker}--
EOF

    email msg,FROM,account.report_email
    end

  end
  def email msg, from, to
   begin
      smtp_host = archive.mailer_smtp_host || "localhost"
      Net::SMTP.start(smtp_host) do |smtp|
        smtp.send_message msg, from, to
     end
   rescue
     raise "email problem rc=#{$!} \nsmtp_host=#{smtp_host},from=#{from},to=#{to}"
   end
 end
end
 
