TAR_COMMAND = %w(tar gnutar).find do |bin|

  path = %x{which #{bin}}

  if $?.exitstatus == 0

    version = %x{tar --version | head -n 1 }.chomp
    
    if version =~ /GNU tar/
      path
    end

  end

end

raise "GNU tar not found on the system"
%x{which tar}

# is it gnu tar?
%x{tar --version | head -n 1 }.chomp =~ /GNU tar/

class Tar
 
  def initialize *files

  end

end
