require 'spec/expectations'
require 'daitss2'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, 'mysql://daitss:topdrawer@localhost/daitss2')
 
# Before do
#   DataMapper.auto_migrate!
# end