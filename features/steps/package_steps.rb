Given /^I submit (a|another|\d+) packages?$/ do |article|
  sip = test_sip_by_name('ateam')

  count = case article
          when "a", "another" then 1
          when /\d+/ then article.to_i
          end

  count.times { bin "submit #{sip}" }

  @aips = Dir["#{ENV['DAITSS_WORKSPACE']}/*"]
end



Given /^(they|it) (are|is) tagged (\w+)$/ do |pronoun, verb, tag|

  to_tag = case pronoun
           when "they" then @aips
           when "it" then @aips[0..0]
           end

  to_tag.each do |aip|
    FileUtils.touch File.join(aip, tag)
  end 

end

Given /^it is invalid$/ do
  sip_descriptor = File.join @aips.first, 'files/ateam.xml'
  open(sip_descriptor, 'a') { |io| io.puts 'this should make it invalid' }
end

Given /^a non\-existent aip$/ do
  @aips = ['XXXX']
end
