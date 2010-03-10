require 'cucumber/rake/task'
require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'semver'
require 'spec/rake/spectask'

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = "--format pretty"
end

# build a gem spec
spec = Gem::Specification.new do |spec|
  spec.name = "daitss-functions"
  spec.email = "flazzarino@gmail.com"
  spec.version = SemVer.find.format '%M.%m.%p'
  spec.summary = "daitss core libraries"
  spec.authors = ["Francesco Lazzarino", "Emmanuel Rodriguez"]
  spec.files = ["Rakefile", "README.md"]
  spec.files += Dir["lib/**/*"]
  spec.files += Dir["spec/**/*"]
  spec.files += Dir["templates/**/*"]
  spec.add_dependency 'daitss-database', '~> 0.2.0'
  spec.add_dependency 'sys-proctable', '~> 0.9.0'
  spec.add_dependency 'libxml-ruby', '>= 1.1.2'
  spec.has_rdoc = true
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

tasks_dir = File.join File.dirname(__FILE__), 'tasks'
require File.join(tasks_dir, "service_stack")
