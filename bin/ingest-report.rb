#!/usr/bin/env ruby

# takes an IEID as input, outputs XML equivalent to a DAITSS Ingest report.

require 'rexml/document'
require 'daitss2'
require 'time'
require 'pp'

# Connect to database
Daitss::CONFIG.load_from_env
DataMapper.setup :default, Daitss::CONFIG['database-url']

IEID = ARGV[0]

def fail message
  STDERR.puts message
  exit 1
end

#def write_file ieid, output
  #filename_flat = File.join PATH_TO_WRITE_FILE, ieid + "_INGEST.xml"
#
  #output_file = File.new filename_flat, "w+"
  #output_file << "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n"
  #output_file << "<?xml-stylesheet type=\"text/xsl\" href=\"daitss_report_xhtml.xsl\"?>\n"
  #output_file << output
#end

# check that destination is a directory
#if not File.directory? PATH_TO_WRITE_FILE
  #fail "Error, #{PATH_TO_WRITE_FILE} is not a directory."
#end
#
# check that destination is writable
#if not File.writable? PATH_TO_WRITE_FILE
  #fail "Error, #{PATH_TO_WRITE_FILE} is not a writable."
#end

# get data from database to build report
intentity_record = Intentity.first(:id => Daitss::CONFIG['uri-prefix'] + IEID)
sip = SubmittedSip.first(:ieid => IEID)

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
ingest_element.attributes["INGEST_TIME"] = sip.operations_events.first(:event_name => "Package Submission").timestamp.to_time.iso8601
ingest_element.attributes["PACKAGE"] = intentity_record.original_name

report_element << ingest_element

# AGREEMENT_INFO element
agreement_info_element = REXML::Element.new "AGREEMENT_INFO"

ingest_element << agreement_info_element

agreement_info_element.attributes["ACCOUNT"] = intentity_record.project.account.code
agreement_info_element.attributes["PROJECT"] = intentity_record.project.code

# FILES element
files_element = REXML::Element.new "FILES"
ingest_element << files_element

# create and add individual file elements
intentity_record.datafiles.each do |datafile_record|
  file_element = REXML::Element.new "FILE"
  md_sha1_element = REXML::Element.new "MESSAGE_DIGEST"

  file_element.attributes["DFID"] = datafile_record.id
  file_element.attributes["ORIGIN"] = datafile_record.origin
  file_element.attributes["PATH"] = datafile_record.original_path
  file_element.attributes["SIZE"] = datafile_record.size

  md_sha1_element.attributes["ALGORITHM"] = "SHA-1"

  md_sha1_element.text = datafile_record.message_digest.first(:code => :sha1).value

  file_element << md_sha1_element
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

  # TODO: add datafile EVENTS
  #if file_hash[1]["EVENTS"].length > 0
    #file_hash[1]["EVENTS"].each do |event|
      #event_element = REXML::Element.new "EVENT"
      #procedure_element = REXML::Element.new "PROCEDURE"
      #note_element = REXML::Element.new "NOTE"
#
      #event_element.attributes["TIME"] = event.DATE_TIME
      #event_element.attributes["OUTCOME"] = event.OUTCOME
#
      #note_element.text = event.NOTE
      #procedure_element.text = event.EVENT_PROCEDURE
#
      #event_element << note_element
      #event_element << procedure_element
#
      #file_element << event_element
    #end
  #end
end

report.add_element report_element

pretty_output = String.new
pretty_printer = REXML::Formatters::Pretty.new
pretty_printer.write(report, pretty_output)

puts pretty_output
#write_file ARGV[0], pretty_output
