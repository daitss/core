require 'erb'

include ERB::Util

def template_by_name name
  file = File.join(File.dirname(__FILE__), '..', 'templates', "#{name}.erb")
  open(file) { |io| ERB.new io.read }
end
