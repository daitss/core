#!/usr/bin/env ruby

require 'sinatra'

# return 400 on HEAD, GET, or DELETE 
head "/" do
  halt 400
end

get "/" do
  halt 400
end

delete "/" do
  halt 400
end

get '/' do 
  "foo"
end
