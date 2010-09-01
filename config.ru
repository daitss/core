require 'rubygems'
require 'bundler/setup'

require 'app'

set :env, :production
disable :run, :reload

run Sinatra::Application
