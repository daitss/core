require 'ruby-prof'

def profile_this
  RubyProf.start
  yield
  result = RubyProf.stop
  printer = RubyProf::GraphHtmlPrinter.new(result)

  profiles = Dir["/tmp/profile-*.html"].map do |f|
    File.basename(f)[%r{profile-(\d+).html}, 1].to_i rescue 0
  end

  n = (profiles.max || 0) + 1

  open "/tmp/profile-#{n}.html", 'w' do |out|
    printer.print(out, :min_percent=>0)
  end

end
