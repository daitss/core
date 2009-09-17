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

TS_DIR = File.join File.dirname(__FILE__), 'test-stack'

task :get_ts do
  
  FileUtils::mkdir_p TS_DIR
  
  vc_urls = {
    'description' => "svn://tupelo.fcla.edu/daitss2/describe/trunk",
    #'storage' => "svn://tupelo.fcla.edu/daitss2/store/trunk",
    'simplestorage' => "ssh://sake/var/git/simplestorage.git",
    'actionplan' => "svn://tupelo.fcla.edu/daitss2/actionplan/trunk",
    'validation' => "svn://tupelo/shades/validate-service",
    'transformation' => "svn://tupelo.fcla.edu/daitss2/transform/trunk"
  }

  Dir.chdir TS_DIR do
    vc_urls.each do |name, url|
      next if File.exist? name
      puts "retrieving #{name}"
      
      if url =~ %r{^svn://}
        `svn export #{url} #{name}`  
      else
        `git archive --remote='#{url}' --format=tar --prefix='simplestorage/' master | tar xf -`
      end
      
      raise "error retrieving #{name}" unless $? == 0
    end
  end
  
end

task :clobber_ts do
  FileUtils::rm_rf TS_DIR
end

task :ts do
  $:.unshift 'spec'
  require 'help/test_stack'
  include TestStack
  
  start_sinatra
  puts 'sinatra stack started'  
end
