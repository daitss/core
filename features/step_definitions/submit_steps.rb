Given /^I submit (a|\d+) packages?$/ do |count|

  count = case count
          when 'a' then 1
          when /\d+/ then count.to_i
          else raise 'invalid count'
          end

  count.times { submit 'haskell-nums-pdf.zip' }
end

When "I select a sip to upload" do
  When "I select \"haskell-nums-pdf\" to upload"
end

When /^I select "([^\"]*)" to upload$/ do |name|
  sips << {:sip => name}
  tar = sip_tarball(name)
  dir = Dir.mktmpdir
  $cleanup << dir
  tar_file = File.join dir, "#{name}.tar"
  open(tar_file, 'w') { |o| o.write tar }
  attach_file 'sip', tar_file
end

Then /^I should be at a package page$/ do
  last_request.path.should =~ %r{/package/\w+}
end
