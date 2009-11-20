#!/usr/bin/env ruby

require 'sinatra'
require 'package_submitter'
require 'digest/md5'
require 'tempfile'
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

  begin
    # return 400 if missing any expected headers
    halt 400, "Missing header: CONTENT_MD5" unless @env["HTTP_CONTENT_MD5"]
    halt 400, "Missing header: X_PACKAGE_NAME" unless @env["HTTP_X_PACKAGE_NAME"]
    halt 400, "Missing header: X_ARCHIVE_TYPE" unless @env["HTTP_X_ARCHIVE_TYPE"]

    # return 400 if X_ARCHIVE_TYPE header is not the expected value of 'zip' or 'tar'

    halt 400, "X_ARCHIVE_TYPE header must be either 'tar' or 'zip'" unless @env["HTTP_X_ARCHIVE_TYPE"] == "tar" or @env["HTTP_X_ARCHIVE_TYPE"] == "zip"

    request.body.rewind

    # return 400 if there is no body in the request
    halt 400, "Missing body" if request.body.eof?

    body_md5 = Digest::MD5.new

    while (buffer = request.body.read 1048576)
      body_md5 << buffer
    end

    # return 412 if md5 of body does not match the provided CONTENT_MD5
    halt 412, "MD5 of body does not match provided CONTENT_MD5" unless @env["HTTP_CONTENT_MD5"] == body_md5.hexdigest

    # write body to a temporary file
    request.body.rewind
    tf = Tempfile.new(@env["HTTP_CONTENT_MD5"])

    while (buffer = request.body.read 1048576)
      tf << buffer
    end



  rescue => e
    halt 500, e.message
  end




end
