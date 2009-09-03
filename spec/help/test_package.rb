require "aip"

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

def next_aip_dir

  taken = Dir["#{$sandbox}/*"].map do |e|
    e =~ /aip-(\d+)/ ? $1.to_i : -1
  end      

  File.join $sandbox, "aip-#{ taken.empty? ? 0 : taken.max + 1 }"
end

def submit_sip name
  sip = test_sip_by_name name
  aip = Aip.make_from_sip next_aip_dir, sip
  aip
end
