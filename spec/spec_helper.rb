require 'open3'
require 'tempfile'
require 'mongrel'

# dir of test sips
TEST_SIP_DIR = File.join 'spec', 'sips'

def test_package name
  File.join Dir.pwd, 'spec', 'packages', name
end

# Return the path of the named sip
def sip_by_name(name)

  # the path to the sip
  path = File.join TEST_SIP_DIR, (name =~ /\.sip$/ ? name : name + '.sip')

  raise "sip #{name} does not exist" unless File.directory? path

  # tar up path
  options = %W{--create --gzip --file -}.join ' '
  Dir.chdir File.dirname(path) do
    tar_data = `tar #{options} #{File.basename path}`
    raise "tar returned #{$?}" unless $? == 0
    tar_data
  end

end

def test_web_server
  Mongrel::HttpServer.new "0.0.0.0", "3003"
end

class MockHandler < Mongrel::HttpHandler

  attr_reader :aips, :incompletes

  def initialize
    @aips = {}
    @routes = {}
    @mutex = Mutex.new
    super
  end

  def process(request, response)

    begin

      case request.params["REQUEST_METHOD"]
      when "POST"
        make_new_aip request, response

      when "GET"
        
        response.start(200) do |head, out|
          head['Content-Type'] = "application/tar"
          pattern = @routes.keys.find { |pattern| pattern === request.params["REQUEST_PATH"] }
          out.write @routes[pattern]
        end
        
      end

    rescue => e

      response.start(500) do |head, out|
        out.write e.message
        out.write e.backtrace
      end

    end

  end

  def make_new_aip(request, response)

    # take the tar data
    t = Tempfile.new 'tardata'
    t.write request.body.read
    t.flush
    stdin, stdout, stderr = Open3.popen3 "tar Otf #{t.path}"
    output = stderr.read
    t.close

    raise "cant extract name from tardata" unless output =~ /^[^\/]+\.sip\//
    name = output.split.first.chop[0..-5]

    @mutex.synchronize do
      @aips[name] = request.body
    end

    response.start(201) do |head, out|
      head['Content-Type'] = "text/xml"
      head['Location'] = name
    end

  end

  def mock(path, body)
    @routes[path] = body
  end

end
