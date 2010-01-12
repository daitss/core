require "wip"
require "wip/create"
require "uuid"

TEST_PACKAGE_DIR = File.join File.dirname(__FILE__), '..', '..', 'test-packages'
TEST_SIPS_DIR = File.join TEST_PACKAGE_DIR, 'sips'
URI_PREFIX = 'test:/'

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
  sip = Sip.new File.join(TEST_SIPS_DIR, name)
  uuid = name # UUID.new.generate
  path = File.join $sandbox, uuid
  uri = URI.join(URI_PREFIX, uuid).to_s
  Wip.make_from_sip path, uri, sip
end
