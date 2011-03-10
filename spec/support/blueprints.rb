require 'machinist/data_mapper'
require 'sham'

Sham.define do
  email { Faker::Internet.free_email }
  boolean(:unique => false) { rand(2) == 0 }
  cap_id { Faker::Company.name.gsub /[^A-Z]/, '' }
  user_id { Faker::Internet.user_name.gsub '.', '' }

  description {
    place = String.new
    place += Faker::Address.city_prefix + ' ' if rand(2) == 0
    place += Faker::Address.state

    if rand(2) == 0
      "University of #{place}"
    else
      "#{place} University"
    end
  }


  address {
<<ADDY
#{Faker::Address.street_address(true)}
#{Faker::Address.city}, #{Faker::Address.state_abbr}
#{Faker::Address.zip_code}
ADDY
  }

  sip_name { |n| "SIP#{n}" }
end

Account.blueprint do
  id { Sham.cap_id }
  description
  report_email { Sham.email }
end

Project.blueprint do
  id { Sham.cap_id }
  description
end

User.blueprint do
  id { Sham.user_id }
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  email
  phone { Faker::PhoneNumber.phone_number }
  address
  is_admin_contact { Sham.boolean }
  is_tech_contact { Sham.boolean }
  account_id { 'OPERATIONS' }
end

Sip.blueprint do
  name { Sham.sip_name }
  size_in_bytes { rand 2**63-1 }
  number_of_datafiles { rand 2**63-1 }
end

Package.blueprint do
  uri { Setting.get('uri prefix').value +  rand(1024 ** 2).to_s(36) }
end

def make_new_package
  p = Package.new
  ac = Account.get OPERATIONS_ACCOUNT_ID
  p.project = ac.default_project
  p.sip = Sip.new :name => "SIP"
  p.save or raise "cant save package"
  p
end

def make_new_wip
  p = make_new_package
  path = File.join DataDir.work_path, p.id
  Wip.create path, :disseminate
end
