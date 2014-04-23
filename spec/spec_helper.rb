require 'fileutils'
require 'data_mapper'

require "daitss"

require_relative "help/test_package"
require_relative "help/sandbox"
require_relative "help/profile"
require_relative "help/agreement"
require_relative "help/fs"

require 'rubygems'
require 'bundler/setup'

require 'datyl/logger'

include Daitss
include Datyl

RSpec.configure do |config|

  config.before :all do
    FileUtils.rm_rf archive.data_dir
    FileUtils.mkdir_p archive.data_dir
    archive.init_data_dir
    archive.setup_db
    archive.init_db
    archive.init_seed

    # some test data
    ac = Account.get("ACT")
    ag = User.new :id => 'Bureaucrat'

    ag.account = ac
    ag.save or "cannot save #{ag.id}"

    $sandbox = Dir.mktmpdir
    $cleanup = [$sandbox]

    Datyl::Logger.setup "Rspec"
    Datyl::Logger.stderr
  end

  config.after :all do
    $cleanup.each { |x| FileUtils.rm_rf x }
  end

end
