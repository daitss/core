require 'erb'

include ERB::Util

def template_by_name name
  file = File::expand_path File::join(File.dirname(__FILE__), '..', 'templates', "#{name}.erb")
  Kernel::open(file) { |io| ERB.new io.read }
end
