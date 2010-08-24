require 'daitss/model/account'
require 'daitss/model/agent'
require 'daitss/model/project'

def setup_agreement
  account = Account.new :name => 'the account', :code => 'ACT'
  account.save or raise "cannot save account"

  agent = Program.new :identifier => 'Bureaucrat', :account => account
  agent.save or raise "cannot save agent"

  project = Project.new :name => 'the project', :code => 'PRJ', :account => account
  project.save or raise "cannot save project"
end
