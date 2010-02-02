require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'cucumber/rake/task'

require 'daitss2'

Cucumber::Rake::Task.new

task :db_migrate do
  DataMapper::auto_migrate!
end


task :db_upgrade do
  DataMapper::auto_upgrade!
end

# build a gem spec
spec = Gem::Specification.new do |spec|
  spec.name = "daitss-database"
  spec.email = "cchou@ufl.edu"
  spec.version = '0.0.0'
  spec.summary = "DAITSS 2 database"
  spec.authors = ["Carol Chou"]
  spec.files = ["Rakefile", "stron/aip.stron"] + Dir["lib/**/*"]
  spec.add_dependency('datamapper', '~> 0.10.2')
  spec.has_rdoc = true
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

