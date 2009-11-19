#!/usr/bin/env ruby

require 'sinatra'
require 'pp'

# return 405 on HEAD, GET, or DELETE 
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
  halt 400, "Missing header: CONTENT_MD5" unless @env["HTTP_CONTENT_MD5"]
  halt 400, "Missing header: X_PACKAGE_NAME" unless @env["HTTP_X_PACKAGE_NAME"]

  request.body.rewind

  halt 400, "Missing body" if request.body.eof?




end
