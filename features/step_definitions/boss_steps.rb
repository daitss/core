Given /^a workspace with many sips$/ do
  sip = test_sip_by_name 'ateam'
  
  2.times do
    `ruby -Ilib bin/submit #{sip}`
    $?.should == 0
  end
  
  @sips = Dir["#{ENV['DAITSS_WORKSPACE']}/*"]
  @sips.should have_exactly(2).items
end

When /^I type boss start$/ do
  `ruby -Ilib bin/boss start`
  #$?.value.should == 0
end

Then /^They should show up in the list$/ do
  output = `ruby -Ilib bin/boss list`
  $?.should == 0
  lines = output.lines.map { |line| line.chomp }
  lines.should == @sips
end
