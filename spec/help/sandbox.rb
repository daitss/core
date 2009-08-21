require 'tempfile'

def new_sandbox
  tf = Tempfile.new 'sandbox'
  path = tf.path
  tf.close!
  path
end
