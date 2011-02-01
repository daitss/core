require 'bundler'
require 'semver'

spec = Gem::Specification.new do |spec|
  spec.name = "daitss"
  spec.email = "flazzarino@gmail.com"
  spec.version = SemVer.find.format '%M.%m.%p'
  spec.summary = "daitss core libraries"
  spec.authors = ["Francesco Lazzarino", "Emmanuel Rodriguez", "Carol Chou"]
  spec.has_rdoc = true

  spec.files = ["Rakefile"]
  spec.files += Dir["lib/**/*"]

  spec.add_bundler_dependencies
end
