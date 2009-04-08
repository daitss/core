require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'cucumber/rake/task'
require 'rake/gempackagetask'

Spec::Rake::SpecTask.new do |t|
  t.libs << 'lib'
  t.libs << 'spec'
  t.spec_opts << "--color"
end

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = "--format pretty"
end

spec = Gem::Specification.new do |spec|
  spec.name = "daitss-ingest"
  spec.version = '0.0.0'
  spec.summary = "DAITSS 2 ingest"
  spec.authors = ["Francesco Lazzarino", "Emmanuel Rodriguez"]
  spec.files = ["Rakefile"] +
    Dir["bin/*", "features/**/*", "lib/*", "spec/*", "tasks/*"]
  spec.executables << 'ingest'
  spec.has_rdoc = true
  
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

task :default => [:spec]
