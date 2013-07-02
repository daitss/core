source "http://rubygems.org"

gem 'data_mapper', ">= 1.2.0"
gem 'dm-is-list'
gem 'haml'
gem 'sass'
gem 'libxml-ruby'
gem 'nokogiri'
gem 'rake'
gem 'semver'
gem 'sinatra'
gem 'rack-ssl-enforcer'
gem 'thor'
gem 'uuid'
gem 'rjb'
gem 'curb'
gem 'dm-postgres-adapter'
gem 'selenium-client'
gem "datyl", :git => "git://github.com/daitss/datyl.git"
gem "log4r"
gem "thin"

group :test do
  gem "cucumber", "1.1.0"
  gem "rack-test"
  gem "rspec"
  gem "fuubar"
  gem "webrat"
  gem 'debugger'
  gem 'ruby-prof'
end

# this gem is WONK

case `uname`.chomp
when 'Darwin'
  gem 'sys-proctable', :path => '~/.rvm/gems/ruby-1.9.3-p429/gems/sys-proctable-0.9.3-universal-darwin'
else
  gem 'sys-proctable'
end

gemspec
