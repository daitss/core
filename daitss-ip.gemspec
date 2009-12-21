Gem::Specification.new do |spec|
  spec.name = 'daitss-ip'
  spec.version = '0.0.0'
  spec.summary = 'DAITSS information packages'
  spec.email = 'flazzarino@gmail.com'
  spec.authors = ['Francesco Lazzarino']

  spec.files = [
    "lib/aip.rb",
    "lib/datafile.rb",
    "lib/fshash.rb",
    "lib/wip/create.rb",
    "lib/wip.rb",
    "lib/xmlns.rb"]

  spec.files += [
    "spec/aip_spec.rb",
    "spec/datafile_spec.rb",
    "spec/fshash_spec.rb",
    "spec/sips/haskell-nums-pdf/haskell-nums-pdf.xml",
    "spec/sips/haskell-nums-pdf/Haskell98numbers.pdf",
    "spec/spec_helper.rb",
    "spec/wip_create_spec.rb",
    "spec/wip_spec.rb"
  ]

  spec.files += ["Rakefile", "daitss-ip.gemspec", "stron/aip.stron"]

  spec.add_dependency 'libxml-ruby', '>= 1.1.3'
  spec.add_dependency 'libxslt-ruby', '>= 0.9.1'
  spec.add_dependency 'datamapper', '~> 0.9.11'
  spec.add_dependency 'schematron', '~> 0.1.1'
end
