# paraphrased from:
# http://johnpwood.net/2010/04/13/getting-rake-test-running-with-rails-3-and-mongodb/
#
# this is here so rake cucubmer can work

namespace :db do
  namespace :test do
    task :prepare do
      # Stub out for DataMapper
    end
  end
end

