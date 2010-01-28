require 'rubygems'
require 'dm-core'
require 'dm-types'
require 'dm-aggregates'

# require all database classes.
pattern = File.expand_path File.join(File.dirname(__FILE__), 'db', '*.rb')
puts pattern.inspect
Dir[pattern].each {|file| require file }

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, 'mysql://root@localhost/daitss2')

