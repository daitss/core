When /^I (type|murmur) "([^\"]*)"$/ do |action, command|
  
  if action == 'type'

    case command
    when /^boss start/, /^boss stop/
      bin_nw command
    else
      @last_output = bin command
    end

  end

end

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

# execute a command and waits for the output
def bin command
  output = %x{ruby -Ilib bin/#{command}}
  $?.should == 0
  output
end

# execute a command but don't care about output
def bin_nw command
  system "ruby -Ilib bin/#{command} > /dev/null 2>&1"
end