require 'ruby-prof'
require 'daitss/proc/wip/process'

module Daitss

  def profile_file suffix
    f = "#{procname}.#{$$}.#{suffix}"
    File.join archive.profile_path, f
  end

  def profile_start
    RubyProf.start
  end

  def profile_stop
    result = RubyProf.stop
    printer = RubyProf::GraphHtmlPrinter.new result
    f = profile_file('prof.html')
    open(f, 'w') { |io| printer.print io, :min_percent => 1 }
  end

  module_function :profile_file
  module_function :profile_start
  module_function :profile_stop
end
