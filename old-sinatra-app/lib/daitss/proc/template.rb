require 'erb'

module Daitss

  include ERB::Util

  TEMPLATE_DIR = File.expand_path File.join(File.dirname(__FILE__), 'template', 'erb')

  def template_by_name name
    file = File.join TEMPLATE_DIR, "#{name}.erb"
    raw = File.read file
    ERB.new raw
  end

end
