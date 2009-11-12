When /^I ingest$/ do
  config_file = File.join $sandbox, 'd2.config'
  open(config_file, 'w') { |io| io.write YAML.dump(Config::Service) }
  @output = `ruby -Ilib bin/ingest -aip #{@aips.first} -config #{config_file}`
end

Given /^it is invalid$/ do
  sip_descriptor = File.join @aips.first, 'files/ateam.xml'
  open(sip_descriptor, 'a') { |io| io.puts 'this should make it invalid' }
end

Given /^a non\-existent aip$/ do
  @aips = ['XXXX']
end

Given /^there is a systemic problem$/ do
  pattern = File.join ENV['DAITSS_WORKSPACE'], "**", "descriptor.xml"
  f = Dir[pattern].first || ENV['DAITSS_WORKSPACE']
  FileUtils::chmod 555, f
end
