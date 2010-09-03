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

end
