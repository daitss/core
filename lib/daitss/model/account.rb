require 'dm-core'
require 'dm-validations'

require 'daitss/model/agent'
require 'daitss/model/project'
require 'daitss/model/request'

class Account
  include DataMapper::Resource

  property :id, String, :key => true
  property :description, Text

  has n, :projects
  has 1, :default_project, 'Project'
  has n, :agents
  has n, :requests

  def Account.system_account
    a = Account.first :id => 'SYSTEM'

    unless a
      a = Account.new :id => 'SYSTEM', :description => 'account for system operations'
      a.save or raise "cannot save system account"
    end

    a
  end

end
