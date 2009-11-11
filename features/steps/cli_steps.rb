Then /^it should print an error message$/ do
  @output.split("\n")[0].should_not be_empty
end

Then /^it should print a backtrace$/ do
  
  @output.split("\n")[1..-1].each do |frame|
    frame.should =~ %r{.+:\d+(:.+)?}
  end
  
end

Then /^it should return status (\d)$/ do |n|
  $?.exitstatus.should == n.to_i
end

Then /^it should print "([^\"]*)"$/ do |message|
  @output.should =~ /#{message}/
end

Given /^a systemic problem$/ do
  pattern = File.join ENV['DAITSS_WORKSPACE'], "**", "descriptor.xml"
  f = Dir[pattern].first || ENV['DAITSS_WORKSPACE']
  FileUtils::chmod 555, f
end
