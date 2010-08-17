require 'rubygems'
require 'bundler'
Bundler.setup

require 'app'

set :env, :production
disable :run, :reload

run Sinatra::Application
