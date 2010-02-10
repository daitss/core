require 'accounts'

class Projects
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :nullable => false
  property :code, String, :nullable => false
  
  belongs_to :account
end
