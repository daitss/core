#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
Bundler.setup

require 'sinatra'
require 'package_submitter'
require 'digest/md5'
require 'tempfile'
require 'digest/sha1'
require 'old_ieid'
require 'daitss/config'

configure do
  Daitss::CONFIG.load_from_env
  DataMapper.setup :default, Daitss::CONFIG['database-url']
end

helpers do
  # returns true if a set of http basic auth credentials passed in

  def credentials?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials
  end

  # returns array containing the basic auth credentials provided, nil otherwise

  def get_credentials
    return nil unless credentials?

    return @auth.credentials
  end

  # returns OperationsAgent object if matching set of credentials found, nil otherwise

  def get_agent
    user_credentials = get_credentials

    return nil if user_credentials == nil

    agent = OperationsAgent.first(:identifier => user_credentials[0])

    if agent && agent.authentication_key.auth_key == Digest::SHA1.hexdigest(user_credentials[1])
      return agent
    else
      return nil
    end
  end
end

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
post "/*" do
  begin
    #return 401 if credentials not provided
    halt 401 unless credentials?

    # return 400 if missing any expected headers
    halt 400, "Missing header: X_PACKAGE_NAME" unless @env["HTTP_X_PACKAGE_NAME"]

    # authenticate
    agent = get_agent
    halt 403 unless agent

    # check authorization if contact
    if agent.type == Contact
      halt 403 unless agent.permissions.include?(:submit)
    end

    # return 400 if there is no body in the request
    request.body.rewind
    halt 400, "Missing body" if request.body.size == 0

    # write body to a temporary file
    request.body.rewind
    tf = Tempfile.new(rand(1000))

    while (buffer = request.body.read 1048576)
      tf << buffer
    end

    tf.rewind

    # call PackageSubmitter to extract file, generate IEID, and write AIP to workspace
    ieid = OldIeid.get_next
    PackageSubmitter.submit_sip ieid, @env["HTTP_X_PACKAGE_NAME"], tf.path, @env["REMOTE_ADDR"], agent

    # send IEID back in response as both header and document in body
    headers["X_IEID"] = ieid.to_s
    "<IEID>#{ieid}</IEID>"

  rescue SipReject => e
    halt 400, "#{ieid}: #{e.message}"
  end
end
