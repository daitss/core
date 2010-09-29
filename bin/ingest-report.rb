#!/usr/bin/env ruby

# takes an IEID as input, outputs XML equivalent to a DAITSS Ingest report.

require 'rexml/document'
require 'daitss/db'
require 'daitss/model'
require 'daitss/archive'
require 'time'
require 'pp'

include Daitss

# Connect to database
DataMapper.setup :default, Archive.instance.db_url

IEID = ARGV[0]

def fail message
  STDERR.puts message
  exit 1
end

# get data from database to build report
intentity_record = Intentity.first(:id => Archive.instance.uri_prefix + "/" + IEID)
package = Package.first(:id => IEID)
sip = package.sip

if not intentity_record
  fail "Error, there is no record that #{ARGV[0]} was ingested. Please try again."
end

# build our XML document object

report = REXML::Document.new

# REPORT element
report_element = REXML::Element.new "REPORT"

report_element.attributes["xmlns"] = "http://www.fcla.edu/dls/md/daitss/"
report_element.attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
report_element.attributes["xsi:schemaLocation"] = "http://www.fcla.edu/dls/md/daitss/ http://www.fcla.edu/dls/md/daitss/daitssReport.xsd"

# INGEST element
ingest_element = REXML::Element.new "INGEST"

ingest_element.attributes["IEID"] = intentity_record.id
ingest_element.attributes["INGEST_TIME"] = Time.parse(package.events.first(:name => "submit").timestamp.to_s).iso8601
ingest_element.attributes["PACKAGE"] = intentity_record.original_name

report_element << ingest_element

# AGREEMENT_INFO element
agreement_info_element = REXML::Element.new "AGREEMENT_INFO"

ingest_element << agreement_info_element

agreement_info_element.attributes["ACCOUNT"] = package.project.account.id
agreement_info_element.attributes["PROJECT"] = package.project.id

# FILES element
files_element = REXML::Element.new "FILES"
ingest_element << files_element

# create and add individual file elements
intentity_record.datafiles.each do |datafile_record|
  file_element = REXML::Element.new "FILE"
  md_sha1_element = REXML::Element.new "MESSAGE_DIGEST"
  md_md5_element = REXML::Element.new "MESSAGE_DIGEST"
  
  file_element.attributes["DFID"] = datafile_record.id
  file_element.attributes["ORIGIN"] = datafile_record.origin
  file_element.attributes["PATH"] = datafile_record.original_path
  file_element.attributes["SIZE"] = datafile_record.size

  md_sha1_element.attributes["ALGORITHM"] = "SHA-1"
  md_sha1_element.text = datafile_record.message_digest.first(:code => "SHA-1").value

  md_md5_element.attributes["ALGORITHM"] = "MD5"
  md_md5_element.text = datafile_record.message_digest.first(:code => "MD5").value

  file_element << md_sha1_element
  file_element << md_md5_element
  files_element << file_element

  # add broken link element if it exists
  if datafile_record.broken_links.any?
    datafile_record.broken_links.each do |broken_link_record|
      broken_link_element = REXML::Element.new "BROKEN_LINK"

      broken_link_element.text = broken_link_record.broken_links

      file_element << broken_link_element
    end
  end 

  # add warning element if there are any severe elements
 
  if datafile_record.datafile_severe_element.any?
    datafile_record.datafile_severe_element.each do |severe_element_record|
      warning_element = REXML::Element.new "WARNING"

      warning_element.attributes["CODE"] = severe_element_record.severe_element.class
      warning_element.text = severe_element_record.severe_element.name

      file_element << warning_element
    end
  end

  # add datafile EVENTS
  PreservationEvent.all(:relatedObjectId => datafile_record.id, :class => DatafileEvent).each do |event|
      event_element = REXML::Element.new "EVENT"
      procedure_element = REXML::Element.new "PROCEDURE"
      note_element = REXML::Element.new "NOTE"


      event_element.attributes["TIME"] = Time.parse(event.datetime.to_s).iso8601
      event_element.attributes["OUTCOME"] = event.outcome
      procedure_element.text = event.e_type
      note_element.text = event.outcome_details

      event_element << note_element
      event_element << procedure_element

      file_element << event_element
  end
end

report.add_element report_element

pretty_output = String.new
pretty_printer = REXML::Formatters::Pretty.new
pretty_printer.write(report, pretty_output)

puts pretty_output
