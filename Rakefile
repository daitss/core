require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'cucumber/rake/task'
require 'semver'
require 'daitss2'
require 'db/aip'

Cucumber::Rake::Task.new

task :db_migrate do
  DataMapper::Logger.new(STDOUT, :debug)  
  DataMapper.setup(:default, 'mysql://daitss:topdrawer@localhost/daitss2')  
  DataMapper::auto_migrate!
  # Account.auto_migrate!
  # Agent.auto_migrate!
  # Audio.auto_migrate!  
  # Bitstream.auto_migrate!
  # Datafile.auto_migrate!
  # DatafileRepresentation.auto_migrate!
  # Document.auto_migrate!
  # Event.auto_migrate!
  # Format.auto_migrate!
  # Image.auto_migrate!
  # Representation.auto_migrate!
  #  Intentity.auto_migrate!
  # AuthenticationKey.auto_migrate!
  # MessageDigest.auto_migrate!
  # ObjectFormat.auto_migrate!
  # OperationsAgent.auto_migrate!
  # OperationsEvent.auto_migrate!
  # Project.auto_migrate!
  # Relationship.auto_migrate!

  # SevereElement.auto_migrate!
  # Text.auto_migrate!
end

task :db_upgrade do
  DataMapper::auto_upgrade!
end

task :aip_migrate do
  repository(:aipstore) do
    Aip.auto_migrate!
  end
end

# build a gem spec
spec = Gem::Specification.new do |spec|
  spec.name = "daitss-database"
  spec.email = "cchou@ufl.edu"
  spec.version = SemVer.find.format '%M.%m.%p'
  spec.summary = "DAITSS 2 database"
  spec.authors = ["Carol Chou", "Francesco Lazzarino"]
  spec.files = ["Rakefile", "stron/aip.stron"] + Dir["lib/**/*"]
  spec.add_dependency 'datamapper', '~> 0.10.2'
  spec.add_dependency 'jxmlvalidator', '~> 0.1.0'
  spec.has_rdoc = true
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

