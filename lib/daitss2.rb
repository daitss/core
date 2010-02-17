require 'rubygems'
require 'namespaces'
require 'dm-core'
require 'dm-types'
require 'dm-aggregates'
#require 'dm-constraints'
require 'db/agent'
require 'db/audio'
require 'db/bitstream'
require 'db/datafile'
require 'db/document'
require 'db/events'
require 'db/format'
require 'db/image'
require 'db/int_entity'
require 'db/message_digest'
require 'db/objectformat'
require 'db/relationship'
require 'db/representation'
require 'db/severe_element'
require 'db/text'
require 'db/accounts'
require 'db/keys'
require 'db/operations_agents'
require 'db/operations_events'
require 'db/projects'

# require all database classes.
# pattern = File.expand_path File.join(File.dirname(__FILE__), 'db', '*.rb')
# puts pattern.inspect
# Dir[pattern].each {|file| require file }

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, 'mysql://root@localhost/daitss2')

