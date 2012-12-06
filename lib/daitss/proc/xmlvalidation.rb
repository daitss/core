require 'rjb'

module Daitss

  class Checker

    def initialize
      @es = []
      @fs = []
      @ws = []
    end

    def error e
      @es << e
    end

    def fatalError e
      @fs << e
    end

    def warning e
      @ws << e
    end

    def bound
      Rjb.bind self, 'org.xml.sax.ErrorHandler'
    end

    def results
      @es.map { |e| convert_exception :error, e } +
        @fs.map { |e| convert_exception :fatal, e } +
        @ws.map { |e| convert_exception :warning, e }
    end

    private

    def convert_exception level, e

      {
        :level => level,
        :message => e.getMessage,
        :line => e.getLineNumber,
        :column => e.getColumnNumber,
        :system_id => e.getSystemId,
        :public_id => e.getPublicId
      }

    end

  end

  # validate a file returning a list of errors
  # this is done in a separate proc because this creates java threads that cause the ruby instance to crash
  def validate_xml f

    rd, wr = IO.pipe

    pid = fork do

      Rjb.load nil, archive.jvm_options

      $stderr.reopen '/dev/null'

      # make a document builder
      jDocumentBuilderFactory = Rjb.import 'javax.xml.parsers.DocumentBuilderFactory'
      factory = jDocumentBuilderFactory.newInstance
      factory.setNamespaceAware true
      factory.setAttribute "http://xml.org/sax/features/validation", true
      factory.setAttribute "http://apache.org/xml/features/validation/schema", true
      factory.setAttribute "http://apache.org/xml/features/validation/schema-full-checking", true
      factory.setAttribute "http://apache.org/xml/features/nonvalidating/load-external-dtd", true
      builder = factory.newDocumentBuilder

      # parse the xml to get any errors
      checker = Checker.new
      builder.setErrorHandler checker.bound
      builder.parse f
      rs = checker.results
      Marshal.dump rs, wr
    end

    wr.close
    begin                   #607
    rs = Marshal.load rd
    Process.wait pid
    rs
    rescue
      rs = [:message=>"#{$!.inspect}",:line=>"unknown"]
    end
  end
  module_function :validate_xml

end
