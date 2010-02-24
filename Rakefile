require 'rake/gempackagetask'

spec = Gem::Specification.new do |spec|
  spec.name = 'daitss-workspace'
  spec.version = Semver.format ""
  spec.summary = 'DAITSS workspace & workspace package'
  spec.email = 'flazzarino@gmail.com'
  spec.authors = ['Francesco Lazzarino']
  spec.files = Dir['lib/**/*'] + Dir['spec/**/*'] 
  spec.files << 'Rakefile'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
