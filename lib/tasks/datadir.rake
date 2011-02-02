DATA_PATHS = [
  'work',
  'stash',
  'submit',
  'disseminate',
  'dispatch',
  'profile',
  'nuke',
  'reports'
]

namespace :data do

  desc 'init data dir'
  task :init => :environment do

    Dir.chdir DATA_DIR do

      DATA_PATHS.each do |p|
        FileUtils.mkdir p
      end

    end

  end

end
