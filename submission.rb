#!/usr/bin/env ruby

require 'sinatra'
require 'pp'

# return 400 on HEAD, GET, or DELETE 
head "/" do
  halt 405
end

get "/" do
  halt 405
end

delete "/" do
  halt 405
end

# All submissions are expected to be POST requests
post '/' do 

  # All incoming requests must include package_name and md5 query parameters
  halt 400, "Missing parameter: package_name" unless params[:package_name]
  halt 400, "Missing parameter: md5" unless params[:md5]

  # All incoming requests must include a body 
  halt 400, "Missing body" unless body


  "foo"
end
