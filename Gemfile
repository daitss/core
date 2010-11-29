source "http://rubygems.org"

gem 'data_mapper'
gem 'dm-is-list'
gem 'haml'
gem 'libxml-ruby'
gem 'nokogiri'
gem 'rake'
gem 'schematron'
gem 'semver'
gem 'sinatra'
gem 'thor'
gem 'uuid'
gem 'rjb'
gem 'typhoeus'

# this gem is WONK
case `uname`.chomp

when 'Darwin'
  gem 'sys-proctable', :path => '/Library/Ruby/Gems/1.8/gems/sys-proctable-0.9.0-x86-darwin-8'

when 'Linux'
  gem 'sys-proctable', :path => '/usr/local/lib/ruby/gems/1.8/gems/sys-proctable-0.9.0-x86-linux'

else
  gem 'sys-proctable'
end

group :test do
  gem "cucumber"
  gem "rack-test"
  gem "rspec"
  gem "fuubar"
  gem "webrat"
  gem 'ruby-debug'
  gem 'ruby-prof'
end

group :sqlite do
  gem "dm-sqlite-adapter"
end

group :postgres do
  gem "dm-postgres-adapter"
end

group :mysql do
  gem "dm-mysql-adapter"
end

group :thin do
  gem 'thin'
end
