namespace :data do
  desc 'init data dir'
  task :init => :environment { DataDir.make_all }
end
