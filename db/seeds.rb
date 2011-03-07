# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

Setting.create :id => 'uri prefix', :value => 'daitss:'
Setting.create :id => 'throttle', :value => '10'
Setting.create :id => 'actionplan server', :value => 'http://localhost:7001'
Setting.create :id => 'describe server', :value => 'http://localhost:7002'
Setting.create :id => 'storage server', :value => 'http://francos.storemaster.ripple.fcla.edu'
Setting.create :id => 'viruscheck server', :value => 'http://localhost:7005'
Setting.create :id => 'transform server', :value => 'http://localhost:7006'
Setting.create :id => 'xmlresolution server', :value => 'http://xmlresolution.ripple.fcla.edu'

sys = Account.create :id => SYSTEM_ACCOUNT_ID, :description => 'system account'
ops = Account.create :id => OPERATIONS_ACCOUNT_ID, :description => 'operations account'

sys.projects.create :id => DEFAULT_PROJECT_ID, :description => 'default project'
ops.projects.create :id => DEFAULT_PROJECT_ID, :description => 'default project'

kernel = Program.create :id => SYSTEM_PROGRAM_ID, :description => "daitss software agent", :account => sys

root = Operator.create :id => ROOT_OPERATOR_ID, :description => "root account", :account => ops
root.encrypt_auth ROOT_OPERATOR_ID
root.save or raise "cannot save system operator password"

AdminLog.create :message => "archive seeded #{Daitss::VERSION}", :agent => kernel
