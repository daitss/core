Given /^a workspace with many aips$/ do
  sip = test_sip_by_name 'ateam'
  2.times { bin "submit #{sip}" }
  @aips = Dir["#{ENV['DAITSS_WORKSPACE']}/*"]
  @aips.should have_exactly(2).items
end

When /^I type boss (start|stop) for (all|a single|that single) packages?$/ do |command, cardinality|
  
  aip = case cardinality
        when "all" then ""
        when "a single", "that" then File.basename @aips.first
        end
  
  bin "boss #{command} #{aip}"
end

When /^I type boss list$/ do
  list_output = bin "boss list"
  @list = list_output.lines.map { |line| line.chomp.split.first }
end

Then /^(they|it) (should|should not) show up in the list$/ do |cardinality, condition|

  subject = case cardinality
            when "they" then @aips
            when "it" then [@aips.first]
            end

  case condition
  when "should"
    @list.should include(*subject)
  when "should not"
    @list.should_not include(*subject)
  end

end

def bin command
  output = %x{ruby -Ilib bin/#{command}}
  $?.should == 0
  output
end