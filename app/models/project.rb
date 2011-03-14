DEFAULT_PROJECT_ID = 'DEFAULT'

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
    Project.new :id => DEFAULT_PROJECT_ID, :description => "default project"
  end

end
