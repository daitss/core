def sip_fixture_path name
  f = Rails.root.join "spec/fixtures/sips", name
  raise "#{f} does not exist" unless File.exist? f
  f
end

def file_fixture_path name
  f = Rails.root.join "spec/fixtures/files", name
  raise "#{f} does not exist" unless File.exist? f
  f
end
