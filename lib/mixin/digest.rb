# OSX SHA1 bug
PLATFORM = %x[uname].chomp

if PLATFORM =~ /darwin/

  class Digest::SHA1

    def update s
      buf_size = (1024 ** 2) * 256

      if s.size > buf_size
        io = StringIO.new s
        buf = String.new
        super buf while io.read(buf_size, buf)
      else
        super s
      end

    end

  end

end

