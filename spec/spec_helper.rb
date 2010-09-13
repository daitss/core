require 'daitss/config'
require 'fileutils'

require 'data_mapper'

require "daitss/model/aip"
require "daitss/model/agent"
require "daitss/model/event"
require "daitss/db"

require "help/test_stack"
require "help/test_package"
require "help/sandbox"
require "help/profile"
require "help/agreement"

SPEC_ROOT = File.dirname __FILE__

Spec::Runner.configure do |config|

  config.before :all do
    Daitss::CONFIG.load_from_env
    FileUtils.mkdir Daitss::CONFIG['data'] unless File.directory? Daitss::CONFIG['data']
    Archive.create_work_directories
    Archive.setup_db
    Archive.init_db
    Archive.create_initial_data

    # some test data
    ac = Account.new :id => 'ACT', :description => 'the description'
    pr = Project.new :id => 'PRJ', :description => 'the description', :account => ac
    dpr = Project.new :id => Archive::DEFAULT_PROJECT_ID, :description => 'the default project', :account => ac
    ag = User.new :id => 'Bureaucrat', :account => ac

    ac.save or "cannot save #{ac.id}"
    pr.save or "cannot save #{pr.id}"
    dpr.save or "cannot save #{dpr.id}"
    ag.save or "cannot save #{ag.id}"

    $sandbox = Dir.mktmpdir
    $cleanup = [$sandbox]

    #setup_agreement
  end

  config.after :all do
    $cleanup.each { |x| FileUtils::rm_rf x }
  end

end
