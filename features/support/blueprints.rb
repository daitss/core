require 'machinist/data_mapper'
require 'sham'

#Before { Sham.reset }

Sham.define do
  email { Faker::Internet.free_email }
  boolean(:unique => false) { rand(2) == 0 }
  cap_id { Faker::Company.name.gsub(/[^A-Z]/, '') }
  user_id { Faker::Internet.user_name.gsub '.', '-' }
  description { Faker::Company.catch_phrase }
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
  account# { Account.make }
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  email
  phone { Faker::PhoneNumber.phone_number }
  address { Faker::Address.street_address }
  is_admin_contact { Sham.boolean }
  is_tech_contact { Sham.boolean }
end
