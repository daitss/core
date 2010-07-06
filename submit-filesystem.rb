#!/usr/bin/env ruby

require 'optparse'
require 'uri'
require 'ostruct'
require 'digest/md5'
require 'fileutils'

# a simple submission client
# takes a specified package on a filesystem, tars it up, and "curls" it to the submission at the specified url as the specified
#    operations agent.
# displays curl output, which contains the IEID.

# dependencies:
# curl, tar

def get_options(args)
  config = OpenStruct.new("url" => nil, "package" => nil, "package_name" => nil)  

  begin
    opts = OptionParser.new do |opt|

      opt.banner << "\nSubmits a SIP to the DAITSS Submission Service"
      opt.on_tail("--help", "Show this message")  { puts opts; exit }

      opt.on("--url URL", String, "URL of service to submit package to, required") { |key|   config.url = key }      
      opt.on("--package PATH", String, "Path on filesystem to SIP to submit, required") { |path|  config.package = path }
      opt.on("--name PACKAGE_NAME", String, "Package name of package being submitted, required") { |name|  config.package_name = name }
      opt.on("--username USERNAME", String, "Operations agent username, required") { |username|  config.username = username }
      opt.on("--password PASSWORD", String, "Operations agent password, required") { |password|  config.password = password }
    end

    opts.parse!(args)

    raise StandardError, "URL not specified" unless config.url
    raise StandardError, "Package not specified" unless config.package
    raise StandardError, "Package name not specified" unless config.package_name
    raise StandardError, "Username not specified" unless config.username
    raise StandardError, "Password not specified" unless config.password

    url_obj = URI.parse(config.url)

    raise StandardError, "Specified URL #{config.url} does not look like an HTTP URL" unless url_obj.scheme == "http"
    raise StandardError, "Specified package path is not a directory" unless File.directory? config.package

  rescue => e         # catch the error from opts.parse! and display
    STDERR.puts "Error parsing command line options:\n#{e.message}\n#{opts}"
    exit 1
  end

  return config
end

# tars directory to /tmp/tarfile. Returns string with path to tar file

def zip_package path_to_package
  zip_path = File.join("/tmp", "tarfile")

  output = `cd #{File.dirname(path_to_package)}; tar -cf #{zip_path} #{File.basename(path_to_package)} 2>&1; cd $PWD`  

  raise "tar returned non-zero exit status: #{output}" if $?.exitstatus != 0

  return zip_path
end

# calls curl to submit package to service

def submit_to_svc url, path_to_zip, package_name, username, password
  output = `curl -X POST -H "X_PACKAGE_NAME:#{package_name}" -H "CONTENT_TYPE:application/tar" -u #{username}:#{password} -T "#{path_to_zip}" -v #{url} 2>&1`

  return output
end

config = get_options(ARGV) or exit
zipfile = zip_package config.package
curl_output = submit_to_svc config.url, zipfile, config.package_name, config.username, config.password
FileUtils.rm_rf zipfile

if curl_output =~ /X_IEID:/
  puts curl_output.split("<IEID>")[1].gsub("</IEID>", "")
else
  puts curl_output
  exit 1
end
