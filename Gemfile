source "http://rubygems.org"

gem 'data_mapper'
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
gem 'dm-mysql-adapter'
gem 'selenium-client'
gem "datyl", :git => "git://github.com/daitss/datyl.git"
gem "log4r"


# this gem is WONK
case `uname`.chomp

when 'Darwin'
  gem 'sys-proctable', :path => '/Library/Ruby/Gems/1.8/gems/sys-proctable-0.9.0-x86-darwin-8'

when 'Linux'
  gem 'sys-proctable', :path => '/opt/ruby-1.8.7/lib/ruby/gems/1.8/gems/sys-proctable-0.9.0-x86-linux/'

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

gemspec
