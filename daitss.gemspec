require 'bundler'

spec = Gem::Specification.new do |spec|
  spec.name = "daitss"
  spec.email = "flazzarino@gmail.com"
  spec.version = '0.15.4'
  spec.summary = "daitss core libraries"
  spec.authors = ["Francesco Lazzarino", "Emmanuel Rodriguez", "Carol Chou"]
  spec.has_rdoc = true
  spec.files = ["Rakefile"]
  spec.files += Dir["lib/**/*"]
  spec.add_bundler_dependencies
end
