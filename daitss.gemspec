require 'yaml'
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
  spec.files += Dir["spec/**/*"]
  spec.files += Dir["templates/**/*"]
  spec.files += Dir["stron/**/*"]

  spec.add_dependency 'semver', '~> 0.1.0'
  spec.add_dependency 'sys-proctable', '~> 0.9.0'
  spec.add_dependency 'libxml-ruby', '>= 1.1.2'
  spec.add_dependency 'data_mapper', '>= 1.0.0.rc3'
  spec.add_dependency 'jxmlvalidator', '~> 0.1.0'
end
