When /^I ingest$/ do
  config_file = File.join $sandbox, 'd2.config'
  open(config_file, 'w') { |io| io.write YAML.dump(CONFIG) }
  @output = `ruby -Ilib bin/ingest #{File.join ENV['WORKSPACE'], @aips.first} #{config_file}`
end

Given /^there is a systemic problem$/ do
  pattern = File.join ENV['WORKSPACE'], "**", "descriptor.xml"
  f = Dir[pattern].first || ENV['WORKSPACE']
  FileUtils::chmod 555, f
end
