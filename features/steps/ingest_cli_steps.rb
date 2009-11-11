When /^I ingest$/ do
  config_file = File.join $sandbox, 'd2.config'
  open(config_file, 'w') { |io| io.write YAML.dump(Config::Service) }
  @output = `ruby -Ilib bin/ingest -aip #{@aips.first} -config #{config_file}`
end

Given /^it is invalid$/ do
  sip_descriptor = File.join @aips.first, 'files/ateam.xml'
  open(sip_descriptor, 'a') { |io| io.puts 'this should make it invalid' }
end

Given /^an non\-existent aip$/ do
  @aips = ['XXXX']
end

# Given /^an? (non\-existent|invalid) aip$/ do |type|
#   
#   @aip = case type
#          when 'non-existent'
#            'XXXXX'
#          when 'good'
#            aip_instance 'good'
#          when 'invalid'
#            aip_instance 'invalid-descriptor'
#          end
#    
# end
