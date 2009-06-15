def test_sip_by_name name
  p = File.join File.dirname(__FILE__), '..', 'test-packages', 'sips', name
  File.expand_path p
end

def test_aip_by_name name
  p = File.join File.dirname(__FILE__), '..', 'test-packages', 'aips', name
  File.expand_path p
end

def aip_instance_path name
  prototype = test_aip_by_name name
  FileUtils::cp_r prototype, $sandbox
  File.join $sandbox, name
end

def aip_instance name
  Aip.new "file:#{aip_instance_path name}"
end

def aip_instance_from_sip name
  sip = test_sip_by_name name
  aip_dir = File.join $sandbox, 'aip'
  aip = Aip.make_from_sip aip_dir, sip
  aip
end

def new_sandbox
  tf = Tempfile.new 'sandbox'
  path = tf.path
  tf.close!    
  path
end