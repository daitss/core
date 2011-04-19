DEFAULT_PROJECT_ID = 'DEFAULT'
DEFAULT_PROJECT_DESCRIPTION = 'default project'

class Project
  include DataMapper::Resource

  property :id, String, :key => true
  property :description, Text

  property :account_id, String, :key => true

  has 0..n, :packages

  belongs_to :account, :key => true

  def composite_key
    "#{account_id}/#{id}"
  end

  def self.new_default_project
    Project.new :id => DEFAULT_PROJECT_ID, :description => DEFAULT_PROJECT_DESCRIPTION
  end

end
