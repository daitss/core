require 'daitss/db/ops/accounts'
require 'daitss/db/ops/operations_agents'
require 'daitss/db/ops/projects'

def setup_agreement
  account = Account.new :name => 'the account', :code => 'ACT'
  account.save or raise "cannot save account"

  agent = Program.new :identifier => 'Bureaucrat', :account => account
  agent.save or raise "cannot save agent"

  project = Project.new :name => 'the project', :code => 'PRJ', :account => account
  project.save or raise "cannot save project"
end
