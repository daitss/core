# Some of these targest must be executed as
#
#     bundle exec rake <target>
#
# esp. :db and :rspec.
# 


require 'rubygems'

require 'rake'
require 'semver'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

require 'daitss/archive'
require 'daitss/db'
require 'daitss/model/aip'

include Daitss

namespace :db do

  task :setup do
    Archive.instance.setup_db :log => true
  end
  
  desc 'migrate the database'
  task :migrate => [:setup] do
    STDERR.puts "db:migrate has been disabled"
    #archive.setup_db :log => true
    #archive.init_db
    # recreate the relationships_premis_event foreign key contrain to allow cascade delete
    DataMapper.repository(:default).adapter.execute("ALTER TABLE relationships drop constraint relationships_premis_event_fk")
    DataMapper.repository(:default).adapter.execute("ALTER TABLE relationships ADD CONSTRAINT relationships_premis_event_fk FOREIGN KEY (premis_event_id) REFERENCES premis_events (id) ON DELETE CASCADE ON UPDATE CASCADE")    
  end

  desc 'upgrade the database'
  task :upgrade => [:setup] do
    archive.setup_db :log => true
    DataMapper.auto_upgrade!
    #uncomment upon rollout
    #DataMapper.repository(:default).adapter.execute("CREATE  INDEX index_formats_name ON formats (format_name)")
    #DataMapper.repository(:default).adapter.execute("CREATE  INDEX index_message_digests_code ON message_digests (code)")
    #DataMapper.repository(:default).adapter.execute("CREATE  INDEX index_severe_elements ON severe_elements (name)")
    # recreate the relationships_premis_event foreign key contrain to allow cascade delete
    DataMapper.repository(:default).adapter.execute("ALTER TABLE relationships drop constraint relationships_premis_event_fk")
    DataMapper.repository(:default).adapter.execute("ALTER TABLE relationships ADD CONSTRAINT relationships_premis_event_fk FOREIGN KEY (premis_event_id) REFERENCES premis_events (id) ON DELETE CASCADE ON UPDATE CASCADE")    

    # correct the :null value entered by datamapper mistakenly
    DataMapper.repository(:default).adapter.execute("update images set datafile_id = null where datafile_id = 'null'");
    DataMapper.repository(:default).adapter.execute("update images set bitstream_id = null where bitstream_id = 'null'");
    DataMapper.repository(:default).adapter.execute("update audios set datafile_id = null where datafile_id = 'null'");
    DataMapper.repository(:default).adapter.execute("update audios set bitstream_id = null where bitstream_id = 'null'");
    DataMapper.repository(:default).adapter.execute("update texts set datafile_id = null where datafile_id = 'null'");
    DataMapper.repository(:default).adapter.execute("update texts set bitstream_id = null where bitstream_id = 'null'");
    DataMapper.repository(:default).adapter.execute("update documents set datafile_id = null where datafile_id = 'null'");
    DataMapper.repository(:default).adapter.execute("update documents set bitstream_id = null where bitstream_id = 'null'");
    DataMapper.repository(:default).adapter.execute("update object_formats set datafile_id = null where datafile_id = 'null'");
    DataMapper.repository(:default).adapter.execute("update object_formats set bitstream_id = null where bitstream_id = 'null'");

    # manually add the following constraints 
    DataMapper.repository(:default).adapter.execute("ALTER TABLE images ADD CONSTRAINT images_datafile_id_fk FOREIGN KEY (datafile_id) REFERENCES datafiles (id) on update cascade on delete cascade");
    DataMapper.repository(:default).adapter.execute("ALTER TABLE images ADD CONSTRAINT images_bitstream_id_fk FOREIGN KEY (bitstream_id) REFERENCES bitstreams (id) on update cascade on delete cascade");
    DataMapper.repository(:default).adapter.execute("ALTER TABLE audios ADD CONSTRAINT audios_datafile_id_fk FOREIGN KEY (datafile_id) REFERENCES datafiles (id) on update cascade on delete cascade");
    DataMapper.repository(:default).adapter.execute("ALTER TABLE audios ADD CONSTRAINT audios_bitstream_id_fk FOREIGN KEY (bitstream_id) REFERENCES bitstreams (id) on update cascade on delete cascade");
    DataMapper.repository(:default).adapter.execute("ALTER TABLE texts ADD CONSTRAINT texts_datafile_id_fk FOREIGN KEY (datafile_id) REFERENCES datafiles (id) on update cascade on delete cascade");
    DataMapper.repository(:default).adapter.execute("ALTER TABLE texts ADD CONSTRAINT texts_bitstream_id_fk FOREIGN KEY (bitstream_id) REFERENCES bitstreams (id) on update cascade on delete cascade");
    DataMapper.repository(:default).adapter.execute("ALTER TABLE documents ADD CONSTRAINT documents_datafile_id_fk FOREIGN KEY (datafile_id) REFERENCES datafiles (id) on update cascade on delete cascade");
    DataMapper.repository(:default).adapter.execute("ALTER TABLE documents ADD CONSTRAINT documents_bitstream_id_fk FOREIGN KEY (bitstream_id) REFERENCES bitstreams (id) on update cascade on delete cascade");
    DataMapper.repository(:default).adapter.execute("ALTER TABLE object_formats ADD CONSTRAINT object_formats_datafile_id_fk FOREIGN KEY (datafile_id) REFERENCES datafiles (id) on update cascade on delete cascade");
    DataMapper.repository(:default).adapter.execute("ALTER TABLE object_formats ADD CONSTRAINT object_formats_bitstream_id_fk FOREIGN KEY (bitstream_id) REFERENCES bitstreams (id) on update cascade on delete cascade");

    # drop the default that were set to string 'null' by datamapper
    DataMapper.repository(:default).adapter.execute("alter table object_formats alter column datafile_id drop default");
    DataMapper.repository(:default).adapter.execute("alter table object_formats alter column bitstream_id drop default");

  end

  desc 'insert initial data into database'
  task :initial_data => [:setup] do
    archive.setup_db :log => true
    Archive.create_initial_data

    a = Account.new :id => 'ACT', :description => 'the description'
    p = Project.new :id => 'PRJ', :description => 'the description', :account => a
    a.save or 'cannot save ACT'
    p.save or 'cannot save PRJ'
  end

end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["-c", "-f Fuubar", "--fail-fast", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/**/*_spec.rb'
end

require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format progress"
end


HOME    = File.expand_path(File.dirname(__FILE__))

desc "Hit the restart button for apache/passenger, pow servers"
task :restart do
  sh "touch #{HOME}/tmp/restart.txt"
end

desc "deploy to darchive's production site (core.fda.fcla.edu)"
task :darchive do
    sh "cap deploy -S target=darchive.fcla.edu:/opt/web-services/sites/core -S who=daitss:daitss"
end

desc "deploy to development site (core.retsina.fcla.edu)"
task :retsina do
    sh "cap deploy -S target=retsina.fcla.edu:/opt/web-services/sites/core -S who=daitss:daitss"
end

desc "deploy to ripple's test site (core.ripple.fcla.edu)"
task :ripple do
    sh "cap deploy -S target=ripple.fcla.edu:/opt/web-services/sites/core -S who=daitss:daitss"
end

desc "deploy to tarchive's coop (core.tarchive.fcla.edu?)"
task :tarchive_coop do
    sh "cap deploy -S target=tarchive.fcla.edu:/opt/web-services/sites/coop/core -S who=daitss:daitss"
end

defaults = [:restart]

task :default => defaults
