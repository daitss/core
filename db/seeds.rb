# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)


system_account = Account.create :id => SYSTEM_ACCOUNT_ID, :description => 'account for system operations', :report_email => 'daitss@localhost'
Project.create :id => DEFAULT_PROJECT_ID, :description => 'default project for system operations', :account => system_account

Program.create :id => SYSTEM_PROGRAM_ID, :description => "daitss software agent", :account => system_account
Program.create :id => D1_PROGRAM_ID, :description => "daitss 1 software agent", :account => system_account

root = Operator.create(:id => ROOT_OPERATOR_ID, :description => "default operator account", :account => system_account)
root.encrypt_auth ROOT_OPERATOR_ID
root.save or raise "cannot save system operator"

AdminLog.create :message => 'archive seeded'
