gem 'schematron', '>= 0.1.0'

require 'libxml'
require 'schematron'

include LibXML

schema_file = File.join(File.dirname(__FILE__), '..', 'stron', "pim.stron")
doc = XML::Document.file schema_file
PIM_STRON = Schematron::Schema.new doc

Spec::Matchers.define :conform_to_pim_bp do

  match do |file|
    XML.default_line_numbers = true
    doc = XML::Document.file file
    @results = PIM_STRON.validate doc
    @results.empty?
  end

  failure_message_for_should do |file|
    lines = [nil] + open(file).readlines
    buf = StringIO.new
    buf.puts "Expected #{file} to conform to PREMIS in METS best practice:"
    
    @results.each do |r|
      buf.puts "#{r[:line]}: #{r[:type]} #{r[:name]}: #{r[:message]}"
      buf.puts lines[r[:line]]
      buf.puts
    end
    
    buf.string
  end
  
  failure_message_for_should_not do |file|
    "Expected #{file} to not conform to PREMIS in METS best practice, but does"
  end
  
end
