Gem::Specification.new do |spec|
  spec.name = "daitss-ingest"
  spec.version = '0.0.0'
  spec.summary = "DAITSS 2 ingest"
  spec.authors = ["Francesco Lazzarino", "Emmanuel Rodriguez"]
  spec.files = Dir["Rakefile", "ingest.gemspec",
                   "bin/*", "features/**/*", "lib/*",
                   "spec/*", "tasks/*"]

  spec.bindir = 'bin'
  spec.executables << 'ingest'
end
