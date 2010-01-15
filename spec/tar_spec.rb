require 'tempfile'
require 'tar'

describe Tar do

  it "should allow addition of files" do
    path = File.join 'foo', 'bar'
    data = 'this is a test blob'
    tar = Tar.new { |t| t.add path, data }

    tio = Tempfile.new 'test-tarball'
    tio.write tar
    tio.flush
    %x{tar xf #{tio.path} #{path}}.should == data
    tio.close!

  end

end
