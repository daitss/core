namespace :data do
  desc 'initialize the data dir'
  task :init => :environment do
    DataDir.make_all
  end
end
