Given /^I submit (a|another) package$/ do |article|
  sip = test_sip_by_name('ateam')
  bin "submit #{sip}"  
  @aips = Dir["#{ENV['DAITSS_WORKSPACE']}/*"]
end

Given /^aip\-0 is one of them$/ do
  aips = Dir["#{ENV['DAITSS_WORKSPACE']}/*"].map { |p| File.basename p }
  aips.should include("aip-0")
end

Given /^it is tagged (\w+)$/ do |tag|
  aip = @aips.first 
  FileUtils.touch File.join(aip, tag)
end

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

Then /^the list should have (\d+) aips?$/ do |size|
  @last_output.lines.map.size.should == size.to_i
end

Then /^(they|it) (should|should not) be in the list$/ do |cardinality, condition|
  state = @last_output.lines.map { |line| line.chomp.split.first }
  
  subject = case cardinality
            when "they" then @aips
            when "it" then [@aips.first]
            end

  case condition
  when "should"
    state.should include(*subject)
  when "should not"
    state.should_not include(*subject)
  end
end

Then /^it should return an exit status of 2$/ do
  $?.exitstatus.should == 2
end

Given /^the following packages with states:$/ do |table|  
  table.rows.each { Given "I submit a package" }
  
  table.rows.each do |aip, state|
    
    case state
    when "pending"
      # do nothing
      
    when "ingesting"
      bin_nw "boss start #{aip}"
      $?.exitstatus.should == 0
      
    when "REJECT", "SNAFU", "STOP"
      tag_file = File.join(ENV['DAITSS_WORKSPACE'], aip, state)
      FileUtils.touch tag_file
      
    end
    
  end
  
  @expected_state_table = table
end

Then /^I should see the packages with the expected states$/ do
  
  actual_state_table = @last_output.lines.inject([["package", "state"]]) do |acc, line|
                         acc << line.chomp.split
                         acc
                       end
                       
  @expected_state_table.diff! actual_state_table
end


def bin command
  output = %x{ruby -Ilib bin/#{command}}
  $?.should == 0
  output
end

def bin_nw command
  system "ruby -Ilib bin/#{command} > /dev/null 2>&1"
end