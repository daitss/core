#!/usr/bin/env ruby

require 'sinatra'
require 'package_submitter'
require 'digest/md5'
require 'tempfile'
require 'digest/sha1'

module Submission

  class App < Sinatra::Base 

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
    post '/*' do 
      begin
        #return 401 if credentials not provided
        halt 401 unless credentials?

        # return 400 if missing any expected headers
        halt 400, "Missing header: CONTENT_MD5" unless @env["HTTP_CONTENT_MD5"]
        halt 400, "Missing header: X_PACKAGE_NAME" unless @env["HTTP_X_PACKAGE_NAME"]
        halt 400, "Missing header: X_ARCHIVE_TYPE" unless @env["HTTP_X_ARCHIVE_TYPE"]

        # return 400 if X_ARCHIVE_TYPE header is not the expected value of 'zip' or 'tar'

        halt 400, "X_ARCHIVE_TYPE header must be either 'tar' or 'zip'" unless @env["HTTP_X_ARCHIVE_TYPE"] == "tar" or @env["HTTP_X_ARCHIVE_TYPE"] == "zip"

        # authenticate
        agent = get_agent
        halt 403 unless agent 

        # check authorization if contact
        if agent.type == Contact
          halt 403 unless agent.permissions.include?(:submit)
        end

        request.body.rewind

        # return 400 if there is no body in the request
        halt 400, "Missing body" if request.body.eof?

        body_md5 = Digest::MD5.new

        while (buffer = request.body.read 1048576)
          body_md5 << buffer
        end

        # return 412 if md5 of body does not match the provided CONTENT_MD5
        halt 412, "MD5 of body (#{body_md5.hexdigest}) does not match provided CONTENT_MD5 (#{@env["HTTP_CONTENT_MD5"]})" unless @env["HTTP_CONTENT_MD5"] == body_md5.hexdigest

        # write body to a temporary file
        request.body.rewind
        tf = Tempfile.new(@env["HTTP_CONTENT_MD5"])

        while (buffer = request.body.read 1048576)
          tf << buffer
        end

        tf.rewind

        # call PackageSubmitter to extract file, generate IEID, and write AIP to workspace
        if @env["HTTP_X_ARCHIVE_TYPE"] == "zip"
          ieid = PackageSubmitter.submit_sip :zip, tf.path, @env["HTTP_X_PACKAGE_NAME"], agent.identifier, @env["REMOTE_ADDR"], @env["HTTP_CONTENT_MD5"]
        elsif @env["HTTP_X_ARCHIVE_TYPE"] == "tar"
          ieid = PackageSubmitter.submit_sip :tar, tf.path, @env["HTTP_X_PACKAGE_NAME"], agent.identifier, @env["REMOTE_ADDR"], @env["HTTP_CONTENT_MD5"]
        end

        headers["X_IEID"] = ieid.to_s
        "<IEID>#{ieid}</IEID>"

      rescue ArchiveExtractionError => e
        halt 400, "Error extracting files in request body, is it malformed?"
      rescue SubmitterDescriptorAccountMismatch => e
        halt 403, "Submitter account does not match account specified in SIP descriptor"
      rescue => e
        halt 500, e.message
      end

    end
  end
end
