Given /^I submit (a|\d+) packages?$/ do |count|

  count = case count
          when 'a' then 1
          when /\d+/ then count.to_i
          else raise 'invalid count'
          end

  count.times { submit 'haskell-nums-pdf.zip' }
end

When /^I select a sip to upload$/ do
  When "I specifically select a good sip to upload"
end

When /^I specifically select a (.*) sip to upload$/ do |sip|

  case sip
  when "good"
    name = 'haskell-nums-pdf'
  when 'checksum mismatch'
    name = 'ateam-checksum-mismatch'
  when 'empty'
    name = 'ateam-missing-contentfile'
  when 'bad project'
    name = 'ateam-bad-project'
  when 'bad account'
    name = 'ateam-bad-account'
  when 'descriptor not well formed'
    name = 'ateam-descriptor-broken'
  when 'descriptor invalid'
    name = 'ateam-descriptor-invalid'
  when 'descriptor missing'
    name = 'ateam-descriptor-missing'
  when 'descriptor in lower directory'
    name = 'FDAD25deb_descriptor_lower'
  when 'missing account attribute'
    name = 'FDAD25ded_missing_account'
  when 'empty account attribute'
    name = 'FDAD25del_account_name'
  when 'missing project attribute'
    name = 'FDAD25ded_missing_project'
  when 'empty project attribute'
    name = 'FDAD25del_project_name'
  when 'descriptor named incorrectly'
    name = 'FDAD25dei_wrong_name'
  when 'no DAITSS agreement'
    name = 'FDAD25dej_no_agreement'
  when 'two DAITSS agreements'
    name = 'FDAD25dek_two_agreements'
  when 'content in lower directory'
    name = 'FDAD25coc_lower_directory'
  when 'empty directory'
    name = 'FDAD25ota_empty_directory'
  when 'name has more than 32 chars'
    name = 'FDAD25otb_more_than_32_characters_name'
  when 'described hidden file'
    name = 'FDAD25otc_described_hidden'
  when 'undescribed hidden file'
    name = 'FDAD25otd_undescribed_hidden'
  when 'special characters'
    name = 'FDAD25ote_special_character'
  when 'lower level special characters'
    name = 'FDAD25otf_character_lower'
  end

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


