When /^I ingest$/ do
  @aip.to_s
  @output = `ruby -Ilib bin/ingest #{@aip.to_s}`
end

Given /^an? (non\-existent|good|invalid) aip$/ do |type|
  
  @aip = case type
         when 'non-existent'
           'XXXXX'
         when 'good'
           aip_instance 'good'
         when 'invalid'
           aip_instance 'invalid-descriptor'
         end
   
end
