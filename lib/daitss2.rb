require 'rubygems'
require 'namespaces'
require 'dm-core'
require 'dm-types'
require 'dm-aggregates'
require 'dm-constraints'
require 'db/agent'
require 'db/audio'
require 'db/image'
require 'db/document'
require 'db/text'
require 'db/objectformat'
require 'db/format'
require 'db/bitstream'
require 'db/severe_element'
require 'db/brokenlinks'
require 'db/datafile'
require 'db/representation'
# require 'db/datafile_severe_element'
#require 'db/datafiles_representations'
require 'db/events'
require 'db/int_entity'
require 'db/message_digest'
require 'db/relationship'

# package tracker database
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
DataMapper.setup(:default, 'mysql://daitss:topdrawer@localhost/daitss2')
