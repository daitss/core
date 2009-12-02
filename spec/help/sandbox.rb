require 'fileutils'
require 'tempfile'

def new_sandbox
  tf = Tempfile.new 'sandbox'
  path = tf.path
  tf.close!

  if block_given?
    FileUtils::mkdir_p path
    yield path
    FileUtils::rm_rf path
  else
    path
  end

end

def nuke_sandbox!
  pattern = File.join $sandbox, '*'
  FileUtils::rm_rf Dir[pattern]
end
