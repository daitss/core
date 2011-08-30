# -*- mode:ruby; -*-
#
#  Set deploy target host/filesystem and test proxy to use from cap command line as so:
#
#  cap deploy  -S target=ripple.fcla.edu:/opt/web-services/sites/storemaster  -S test_proxy=sake.fcla.edu:3128
#
#  The test-proxy is used only in remote spec tests.
#  One can over-ride user and group settings using -S who=user:group

require 'rubygems'
require 'railsless-deploy'

# we run our own bundle install on deployment to work around conditionalized system path
# in the Gemfile;  we don't want to check in a Gemfile.lock file for this service.
#
# require 'bundler/capistrano'

set :repository,   "git://github.com/daitss/core.git"
set :scm,          "git"
set :branch,       "master"

set :use_sudo,     false
set :user,         "daitss"
set :group,        "daitss" 

set :keep_releases, 5   # default is 5


def usage(*messages)
  STDERR.puts "Usage: cap deploy -S target=<host:filesystem>"  
  STDERR.puts messages.join("\n")
  STDERR.puts "You may set the remote user and group by using -S who=<user:group>. Defaults to #{user}:#{group}."
  STDERR.puts "If you set the user, you must be able to ssh to the target host as that user."
  STDERR.puts "You may set the branch in a similar manner: -S branch=<branch name> (defaults to #{variables[:branch]})."
  exit
end

usage('The deployment target was not set (e.g., target=ripple.fcla.edu:/opt/web-services/sites/silos).') unless (variables[:target] and variables[:target] =~ %r{.*:.*})

_domain, _filesystem = variables[:target].split(':', 2)

set :deploy_to,  _filesystem
set :domain,     _domain

if (variables[:who] and variables[:who] =~ %r{.*:.*})
  _user, _group = variables[:who].split(':', 2)
  set :user,  _user
  set :group, _group
end

role :app, domain

after "deploy:update", "deploy:bundle", "deploy:layout"

namespace :deploy do

  desc "Touch the tmp/restart.txt file on the target host, which signals passenger phusion to reload the app"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end
  
  desc "Create the directory hierarchy, as necessary, on the target host"
  task :layout, :roles => :app do
    # make everything group ownership daitss, for easy maintenance.
    run "find #{shared_path} #{release_path} -print0 | xargs -0 chgrp #{group}"
    run "find #{shared_path} #{release_path} -print0 -type d | xargs -0 chmod 2775"
    run "find #{shared_path} #{release_path} -print0 -type f | xargs -0 chmod g+rwX"
  end


  # Note: JAVA_HOME, GEM and path to bundle must be set correctly for the 
  # deployment user on the deployment host

  desc "DIY bundle to work around conditional system path issues"
  task :bundle, :roles => :app do
    run "cd #{release_path}; which bundle"
    run "cd #{release_path}; bundle install --path #{File.join(shared_path, 'bundle')}"
  end
  
end

