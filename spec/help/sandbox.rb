require 'fileutils'
require 'tempfile'

def new_sandbox
  tf = Tempfile.new 'sandbox'
  path = tf.path
  tf.close!
  path
end

def nuke_sandbox!
  pattern = File.join $sandbox, '*'
  FileUtils::rm_rf Dir[pattern]
end
