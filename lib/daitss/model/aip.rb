require "data_mapper"

require 'libxml'
require 'schematron'
require 'jxml/validator'
require 'net/http'

require 'daitss/archive'
require 'daitss/model/copy'

include LibXML
XML.default_line_numbers = true

stron_file = File.join File.dirname(__FILE__), 'aip', 'aip.stron'
stron_doc = open(stron_file) { |io| XML::Document.io io }
AIP_DESCRIPTOR_SCHEMATRON = Schematron::Schema.new stron_doc

XML_SCHEMA_VALIDATOR = JXML::Validator.new

XML_SIZE = 2**32-1

# authoritative aip record
module Daitss

  class Aip
    include DataMapper::Resource
    property :id, Serial

    property :xml, Text, :required => true, :length => XML_SIZE
    property :datafile_count, Integer, :min => 1, :required => true

    belongs_to :package
    has 1, :copy

    validates_with_method :xml, :validate_against_xmlschema
    validates_with_method :xml, :validate_against_schematron

    def validate_against_xmlschema
      doc = XML::Document.string xml
      results = XML_SCHEMA_VALIDATOR.validate doc
      combined_results = results[:fatals] + results[:errors]
      combined_results.reject! { |r| r[:message] =~ /(tcf|aes)\:/ }
      combined_results.reject! { |r| r[:message] =~ /agentNote/ }

      unless combined_results.empty?
        combined_results.each { |r| puts r[:line].to_s + ' ' + r[:message] }
        [false, "descriptor fails daitss aip xml validation (#{combined_results.size} errors)"]
      else
        true
      end

    end

    # SMELL ditch this
    def validate_against_schematron
      doc = XML::Document.string xml
      results = AIP_DESCRIPTOR_SCHEMATRON.validate doc
      errors = results.reject { |e| e[:rule_type] == 'report' }

      unless errors.empty?
        errors.each { |r| puts r[:line].to_s + ' ' + r[:message] }
        [false, "descriptor fails daitss aip schematron validation (#{errors.size} errors)"]
      else
        true
      end

    end

  end

end
