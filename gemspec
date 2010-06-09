require 'bundler'
require 'semver'

spec = Gem::Specification.new do |spec|
  spec.name = "daitss"
  spec.email = "flazzarino@gmail.com"
  spec.version = SemVer.find.format '%M.%m.%p'
  spec.summary = "daitss core libraries"
  spec.authors = ["Francesco Lazzarino", "Emmanuel Rodriguez", "Carol Chou"]
  spec.has_rdoc = true

  spec.files = ["Rakefile", "README.md"]
  spec.files += Dir["lib/**/*"]
  # spec.files += Dir["spec/**/*"]
  spec.files += Dir["templates/**/*"]
  spec.files += Dir["stron/**/*"]
  spec.files << "bin/daitss"
  spec.files << "bin/ingest"

  spec.executables = ['daitss', 'ingest']

  spec.add_bundler_dependencies
end
