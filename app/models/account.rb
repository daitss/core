SYSTEM_ACCOUNT_ID = 'SYSTEM'
OPERATIONS_ACCOUNT_ID = 'OPERATIONS'

class Account
  include DataMapper::Resource

  property :id, String, :key => true
  property :description, Text
  property :report_email, String

  has 1..n, :projects, :constraint => :destroy
  has n, :agents

  before :valid? do

    if new?
      self.projects << Project.new_default_project
    end

  end

  validates_with_block :projects do

    if default_project
      true
    else
      [false, 'default project is missing']
    end

  end

  def default_project
    projects.first :id => DEFAULT_PROJECT_ID
  end

end
