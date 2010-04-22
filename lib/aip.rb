require "dm-core"
require 'dm-validations'
require 'dm-types'

require 'libxml'
require 'schematron'
require 'uri'
require 'jxml/validator'
require 'daitss/config'
require 'net/http'

include LibXML

XML.default_line_numbers = true
stron_file = File.join File.dirname(__FILE__), '..', 'stron', 'aip.stron'
stron_doc = open(stron_file) { |io| XML::Document.io io }
AIP_DESCRIPTOR_SCHEMATRON = Schematron::Schema.new stron_doc
XML_SCHEMA_VALIDATOR = JXML::Validator.new

# authoritative aip record
class Aip

  include DataMapper::Resource
  property :id, String, :key => true # daitss1 ieid
  property :uri, String, :unique => true, :required => true
  property :xml, Text, :required => true, :length => 2**32-1
  property :copy_url, URI, :required => true
  property :copy_sha1, String, :length => 40, :format => %r([a-f0-9]{40}), :required => true
  property :copy_md5, String, :length => 40, :format => %r([a-f0-9]{32}), :required => true
  property :copy_size, Integer, :min => 1, :required => true
  property :needs_work, Boolean, :required => true

  validates_with_method :xml, :validate_against_xmlschema
  validates_with_method :xml, :validate_against_schematron
  validates_with_method :copy_size, :check_copy_size
  validates_with_method :copy_md5, :check_copy_md5

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

  def check_copy_size
    res = head_copy

    unless res['Content-Length'].to_i == copy_size
      [false, "copy size is wrong: #{copy_size} (record) != #{res['Content-Length']} (silo)"]
    else
      true
    end

  end

  def check_copy_md5
    res = head_copy

    unless res['Content-MD5'] == copy_md5
      [false, "copy fixity is wrong: #{copy_md5} (record) != #{res['Content-MD5']} (silo)"]
    else
      true
    end

  end

  def head_copy
    u = ::URI.parse copy_url
    req = Net::HTTP::Head.new u.path
    res = Net::HTTP.start(u.host, u.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request req
    end

    case res
    when Net::HTTPSuccess then res
    else res.error!
    end
  end

end
