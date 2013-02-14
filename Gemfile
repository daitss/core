source "http://rubygems.org"

gem 'data_mapper', ">= 1.2.0"
gem 'dm-is-list'
gem 'haml'
gem 'libxml-ruby', "1.1.3"
gem 'nokogiri'
gem 'rake'
gem 'semver'
gem 'sinatra'
gem 'rack-ssl-enforcer'
gem 'thor'
gem 'uuid'
gem 'rjb'
gem 'curb', '0.7.15'
gem 'dm-postgres-adapter'
gem 'selenium-client'
gem "datyl", :git => "git://github.com/daitss/datyl.git"
gem "log4r"
gem "thin"
# this gem is WONK
case `uname`.chomp

when 'Darwin'
  gem 'sys-proctable', :path => '/Library/Ruby/Gems/1.8/gems/sys-proctable-0.9.1-universal-darwin'

else
  gem 'sys-proctable'
end

group :test do
  gem "cucumber", "1.1.0"
  gem "rack-test"
  gem "rspec"
  gem "fuubar"
  gem "webrat"
  gem 'ruby-debug'
  gem 'ruby-prof'
end

gemspec
