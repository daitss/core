# SMELL use Dir.mktempdir and be done with it

require 'tempfile'
require 'fileutils'

module Daitss

  class Tempdir

    attr_reader :path

    def initialize
      t = Tempfile.new 'tempdir'
      @path = t.path
      t.close!
      FileUtils::mkdir @path

      if block_given?
        yield self
        rm_rf
      end

    end

    def rmdir
      FileUtils::rmdir @path
    end

    def rm_rf
      FileUtils::rm_rf @path
    end

    def to_s
      @path
    end

  end

end
