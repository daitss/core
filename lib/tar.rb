TAR_COMMAND = %w(tar gnutar).find do |bin|

  path = %x{which #{bin}}

  if $?.exitstatus == 0

    version = %x{#{bin} --version }.lines.first.chomp
    
    if version =~ /GNU tar/
      path
    end

  end

end

raise "GNU tar not found on the system" unless TAR_COMMAND

class Tar
 
  attr_reader :path

  def initialize

    # a place to put the tardata
    tempfile = Tempfile.new 'tarball'
    @path = tempfile.path
    tempfile.close!

    yield self if block_given?
  end

  def add path, data
    Tempfile.new 'tarball-entry'
  end

end
