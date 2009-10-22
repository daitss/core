When /^I ingest$/ do
  config_file = File.join $sandbox, 'd2.config'
  open(config_file, 'w') { |io| io.write YAML.dump(Config::Service) }
  @output = `ruby -Ilib bin/ingest -aip #{@aip.to_s} -config #{config_file}`
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
