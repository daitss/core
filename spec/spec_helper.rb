require 'fileutils'

require 'data_mapper'

require "daitss/archive"
require "daitss/model/aip"
require "daitss/model/agent"
require "daitss/model/event"
require "daitss/db"

require "help/test_package"
require "help/sandbox"
require "help/profile"
require "help/agreement"

SPEC_ROOT = File.dirname __FILE__

Spec::Runner.configure do |config|

  config.before :all do
    archive = Daitss::Archive.instance
    FileUtils.rm_rf archive.data_dir
    FileUtils.mkdir archive.data_dir
    archive.init_data_dir
    archive.setup_db
    archive.init_db
    archive.create_initial_data

    # some test data
    ac = Account.new :id => 'ACT', :description => 'the description'
    dpr = Project.new :id => Daitss::Archive::DEFAULT_PROJECT_ID, :description => 'the default project'
    pr = Project.new :id => 'PRJ', :description => 'the description'
    ag = User.new :id => 'Bureaucrat'

    dpr.account = ac
    pr.account = ac
    ac.projects << dpr
    ac.projects << pr
    ac.agents << ag

    ac.save or "cannot save #{ac.id}"
    pr.save or "cannot save #{pr.id}"
    dpr.save or "cannot save #{dpr.id}"
    ag.save or "cannot save #{ag.id}"

    $sandbox = Dir.mktmpdir
    $cleanup = [$sandbox]
  end

  config.after :all do
    $cleanup.each { |x| FileUtils.rm_rf x }
  end

end
