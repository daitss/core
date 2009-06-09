require 'namespace'

module Described
  
  def describe
    s_url = "http://localhost:4568/describe?location=#{CGI::escape to_s }"
    results_doc = open(s_url) { |resp| XML::Parser.io(resp).parse }
    descriptor_doc = XML::Parser.file(@aip.descriptor).parse
    import_events results_doc, descriptor_doc
  end
    
  def described?
    false
  end
  
end