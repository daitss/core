require 'rake'
require 'semver'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('examples_with_rcov') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.rcov = true
  #t.rcov_opts = ['--exclude', 'spec']
end

# run the specs
Spec::Rake::SpecTask.new do |t|
  t.libs << 'lib'
  t.libs << 'spec'
  t.spec_opts << "--color"
end

# build a gem spec
spec = Gem::Specification.new do |spec|
  spec.name = "daitss-functions"
  spec.email = "flazzarino@gmail.com"
  spec.version = SemVer.find.format '%M.%m.%p'
  spec.summary = "daitss modules: ingest, disseminate, & workspace"
  spec.authors = ["Francesco Lazzarino"]
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
