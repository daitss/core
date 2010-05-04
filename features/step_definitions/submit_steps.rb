Given /^xI submit (a|\d+) sips?$/ do |count|

  count = case count
          when 'a' then 1
          when /\d+/ then count.to_i
          else raise 'invalid count'
          end

  count.times { submit 'ateam' }

end

When /^I select a sip to upload$/ do
  name = 'ateam'
  tar = sip_tarball(name)
  tio = Tempfile.open 'cuke'
  dir = tio.path
  tio.close!
  FileUtils.mkdir dir
  tar_file = File.join dir, "#{name}.tar"
  open(tar_file, 'w') { |o| o.write tar }
  attach_file 'sip', tar_file
  $cleanup << dir
end

Then /^I should be at a wip page$/ do
  #debugger
  #redirected_to
  last_request.path.should =~ %r{/workspace/\w+}
end
