module Daitss

  class FsHash

    include Enumerable

    attr_reader :path

    def initialize dir
      @path = dir
    end

    def []= key, data
      open(key_path(key), "w") { |io| io.write data }
    end

    def [] key
      open(key_path(key)) { |io| io.read } if self.has_key? key
    end

    def keys
      Dir.chdir(@path) { Dir['*'] }
    end

    def has_key? key
      File.exist? key_path(key)
    end

    def keys_like pattern
      keys.select { |k| k =~ pattern }
    end

    def delete key
      FileUtils.rm key_path(key)
    end

    def each
      keys.each { |key| yield [key, self[key]] }
    end

    private

    def key_path key
      File.join @path, key
    end

  end

end
