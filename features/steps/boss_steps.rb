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
