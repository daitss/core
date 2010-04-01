require 'cucumber/rake/task'
require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'semver'
require 'spec/rake/spectask'
require 'daitss2'
require 'db/aip'

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = "--format pretty"
end

task :db_migrate do
  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.setup(:default, 'mysql://daitss:topdrawer@localhost/daitss2')
  DataMapper::auto_migrate!
end

task :db_upgrade do
  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.setup(:default, 'mysql://daitss:topdrawer@localhost/daitss2')
  DataMapper::auto_upgrade!
end

task :aip_migrate do

  repository(:aipstore) do
    Aip.auto_migrate!
  end

end

# build a gem spec
spec = Gem::Specification.new do |spec|
  spec.name = "daitss-core"
  spec.email = "flazzarino@gmail.com"
  spec.version = SemVer.find.format '%M.%m.%p'
  spec.summary = "daitss core libraries"
  spec.authors = ["Francesco Lazzarino", "Emmanuel Rodriguez", "Carol Chou"]
  spec.has_rdoc = true

  spec.files = ["Rakefile", "README.md"]
  spec.files += Dir["lib/**/*"]
  spec.files += Dir["spec/**/*"]
  spec.files += Dir["templates/**/*"]
  spec.files += Dir["stron/**/*"]

  spec.add_dependency 'semver', '~> 0.1.0'
  spec.add_dependency 'sys-proctable', '~> 0.9.0'
  spec.add_dependency 'libxml-ruby', '>= 1.1.2'
  spec.add_dependency 'datamapper', '~> 0.10.2'
  spec.add_dependency 'jxmlvalidator', '~> 0.1.0'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

tasks_dir = File.join File.dirname(__FILE__), 'tasks'
require File.join(tasks_dir, "service_stack")
