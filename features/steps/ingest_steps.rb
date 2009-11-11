Given /^an (unresolvable|unknown) package url$/ do |type|
  @url = case type
         when 'unknown'
           'xxx://should/not/work'
         when 'unresolvable'
           'file://should/not/work'
         end
end

When /^I ingest it$/ do
  config_file = File.join File.dirname(__FILE__), '../../spec/config/teststack.yml'
  @output = bin "ingest -aip #{@url} -config #{config_file}"
end

Then /^I should get an (unresolvable|unknown) error$/ do |type|

  case type
  when 'unresolvable'
    @output.should match(/cannot locate package/)
  when 'unknown'
    @output.should match(/unsupported url/)
  end

end

Given /^an aip that will fail validation$/ do
  @url = "file:" + package_instance('empty')
end

Given /^a partially ingested AIP$/ do
  path = package_instance 'incomplete'
  @url = "file:" + path
end

Then /^there should be no duplicate events$/ do
  
  # package level events
  p_pattern = File.join URI.parse(@url).path, 'md', 'aip', 'digiprov-*.xml'

  p_types = []
  Dir[p_pattern].each do |file|
    doc = open(file) { |io| XML::Parser.io(io).parse }
    
    doc.find('//premis:event', NS_MAP).each do |e|
      et = e.find_first('premis:eventType', NS_MAP).content.strip
      p_types.should_not include(et)
      p_types << et
    end
    
  end
  
  
  # file level events
  f_pattern = File.join URI.parse(@url).path, 'md', '*'
  file_md_dirs = Dir[p_pattern].reject { |file| file =~ %r{md/aip} }
  

  file_md_dirs.each do |file_md_dir|
    Dir.chdir(file_md_dir) do
      f_types = []
      
      Dir["digiprov-*.xml"].each do |file|
        et = e.find_first('premis:eventType', NS_MAP).content.strip
        f_types.should_not include(et)
        f_types << et
      end
      
    end
    
  end
  
end

Given /^a error of (any|\d{3}) error when performing (.+)$/ do |status, service|
  pending
  case service
  when 'validation'
    $service_urls[:validation] = 'http://localhost:7000/dummy/#{level}'
  else
    pending
  end
end

Then /^the package should be (ingested|rejected|snafu)$/ do |status|
  @output.should match(/#{status}/m)
end
