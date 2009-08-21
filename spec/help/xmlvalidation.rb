require 'rjb'

# setup rjb validator
jar_file = File.join(File.dirname(__FILE__), '..', '..', 'ext', 'xmlvalidator.jar')
ENV['CLASSPATH'] = if ENV['CLASSPATH']
  "#{jar_file}:#{ENV['CLASSPATH']}"
else
  jar_file
end

Java_File = Rjb.import 'java.io.File'
Java_Validator = Rjb.import 'edu.fcla.da.xml.Validator'

module ErrorCollection

  def each
    (0...size).map { |n| yield elementAt(n) }
  end
  
  include Enumerable
end

Spec::Matchers.define :be_valid_xml do

  match do |file|

    # validate the file
    jvalidator = Java_Validator.new
    jfile = Java_File.new file
    jchecker = jvalidator.validate jfile

    # make some usable data structures out of it
    @fatals = jchecker.getFatals
    @errors = jchecker.getErrors
    @warnings = jchecker.getWarnings
    [@fatals, @errors, @warnings].each { |cat| cat.extend ErrorCollection }
    
    # make sure they are all empty
    [@fatals, @errors, @warnings].all? { |cat| cat.empty? }
  end

  failure_message_for_should do |file|
    lines = [nil] + open(file).readlines
    
    buf = StringIO.new
    buf.puts "Expected valid xml in #{file}:"
    buf.puts "Fatals: #{@fatals.size}" 
    @fatals.each do |e|
      buf.puts "#{e.getLineNumber}: #{e.getMessage}"
      buf.puts lines[e.getLineNumber]
    end
    buf.puts
    
    buf.puts "Errors: #{@errors.size}" 
    @errors.each do |e|
      buf.puts"#{e.getLineNumber}: #{e.getMessage}"
      buf.puts lines[e.getLineNumber]
    end
    buf.puts    
    
    buf.puts "Warnings: #{@warnings.size}" 
    @warnings.each do |e|
      buf.puts "#{e.getLineNumber}: #{e.getMessage}"
      buf.puts lines[e.getLineNumber]
    end
    
    buf.string
  end

  failure_message_for_should_not do |file|
    "Expected invalid xml in #{file}, validated"
  end

end
