# -*- mode:ruby; -*-
#
#  Set deploy target host/filesystem and test proxy to use from cap command line as so:
#
#  cap deploy  -S target=ripple.fcla.edu:/opt/web-services/sites/core
#
#  You can over-ride user and group settings using -S who=user:group - defaults to daitss

require 'rubygems'
require 'railsless-deploy'

# we run our own bundle install on deployment to work around a
# conditionalized system path in the Gemfile; we don't want to check
# in a Gemfile.lock file for this service.
#
# require 'bundler/capistrano'

set :repository,   "git://github.com/daitss/core.git"
set :scm,          "git"
set :branch,       "master"

set :use_sudo,     false
set :user,         "daitss"
set :group,        "daitss" 

# doesn't save enough to be worthwhile:
# set :git_shallow_clone, 1   # only works with master branch, only copy last commit

set :keep_releases, 3   # default is 5

if variables[:target] =~ /ripple.fcla.edu/
  set :keep_releases, 2   # default is 5
end

def usage(*messages)
  STDERR.puts "Usage: cap deploy -S target=<host:filesystem>"  
  STDERR.puts messages.join("\n")
  STDERR.puts "You may set the remote user and group by using -S who=<user:group>. Defaults to #{user}:#{group}."
  STDERR.puts "If you set the user, you must be able to ssh to the target host as that user."
  STDERR.puts "You may set the branch in a similar manner: -S branch=<branch name> (defaults to #{variables[:branch]})."
  exit
end

usage('The deployment target was not set (e.g., target=ripple.fcla.edu:/opt/web-services/sites/core).') unless (variables[:target] and variables[:target] =~ %r{.*:.*})

_domain, _filesystem = variables[:target].split(':', 2)

set :deploy_to,  _filesystem
set :domain,     _domain

set :default_environment, { 
  'PATH' => "/opt/ruby-1.9.3-p545/bin:$PATH",
  'RUBY_VERSION' => 'ruby 1.9.3-p545'
}

if (variables[:who] and variables[:who] =~ %r{.*:.*})
  _user, _group = variables[:who].split(':', 2)
  set :user,  _user
  set :group, _group
end

role :app, domain

after "deploy:update", "deploy:bundle", "deploy:layout"

namespace :deploy do
  
  desc "Create the directory hierarchy, as necessary, on the target host"
  task :layout, :roles => :app do
    if variables[:target] =~ /darchive.fcla.edu/
      run "mv #{release_path}/Rakefile.safe #{release_path}/Rakefile"
      run "mv #{release_path}/bin/init.safe #{release_path}/bin/init"
    else
      run "rm #{release_path}/Rakefile.safe"
      run "rm #{release_path}/bin/init.safe"
    end
  end

  # Note: JAVA_HOME, GEM_HOME and PATH to bundle must be set correctly for the 
  # deployment user on the deployment host

  desc "DIY bundle to work around conditional system path issues"
  task :bundle, :roles => :app do
    run "cd #{release_path}; bundle install --path #{File.join(shared_path, 'bundle')}"
  end
  
end

