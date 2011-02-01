require 'daitss/model/account'
require 'daitss/model/agent'
require 'daitss/model/project'

def setup_agreement
  account = Account.new :id => 'ACT', :description => 'the account'
  account.save or raise "cannot save account"

  agent = Program.new :id => 'Bureaucrat', :account => account
  agent.save or raise "cannot save agent"

  project = Project.new :id => 'PRJ', :description => 'the project', :account => account
  project.save or raise "cannot save project"
end
