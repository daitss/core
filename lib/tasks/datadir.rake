namespace :daitss do
  namespace :data do
    desc 'init data dir'
    task :init => :environment do
      DataDir.make_all
    end
  end
end
