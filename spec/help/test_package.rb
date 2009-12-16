require "wip"
require "uuid"

def test_package_dir
  File.join File.dirname(__FILE__), '..', '..', 'test-packages'
end

def test_sip_by_name name
  p = File.join test_package_dir, 'sips', name
  File.expand_path p
end

def test_aip_by_name name
  p = File.join test_package_dir, 'aips', name
  File.expand_path p
end

def aip_instance_path name
  prototype = test_aip_by_name name
  FileUtils::cp_r prototype, $sandbox
  path = File.join $sandbox, name
  path
end

def aip_instance name
  Aip.new "file:#{aip_instance_path name}"
end

def aip_instance_from_sip name
  sip = test_sip_by_name name
  path = File.join $sandbox, 'aip'
  Wip.make_from_sip path, sip
end

def submit_sip name
  sip = Sip.new test_sip_by_name name
  path = File.join $sandbox, UUID.new.generate
  Wip.make_from_sip path, sip
end
