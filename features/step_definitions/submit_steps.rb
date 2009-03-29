Given "a sip tarball" do
  @sip = sip_by_name 'ateam'
end

When "I submit it" do
  
  begin
    @aip = @archive.create_aip @sip
  rescue => e
    @errors << e
  end
  
end

Then "it should be accessable as an aip" do
  @aip.should be_exist
end

Then "it should be not accepted by the system" do
  @errors.should be_empty
end

Given "a random string of bytes" do
  @sip = open("/dev/random") { |io| io.read 1024 }
end


Then /^(no errors|errors) should be reported$/ do |errors|
  pending "not here yet"
  if errors == "no errors"

  end
end
