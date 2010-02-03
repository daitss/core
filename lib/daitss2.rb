require 'rubygems'
require 'dm-core'
require 'dm-types'
require 'dm-aggregates'
require 'db/agent'
require 'db/audio'
require 'db/bitstream.rb'
require 'db/datafile.rb'
require 'db/document.rb'
require 'db/events.rb'
require 'db/format.rb'
require 'db/image.rb'
require 'db/int_entity.rb'
require 'db/objectformat.rb'
require 'db/relationship.rb'
require 'db/representation.rb'
require 'db/severe_element.rb'
require 'db/text.rb'

# require all database classes.
# pattern = File.expand_path File.join(File.dirname(__FILE__), 'db', '*.rb')
# puts pattern.inspect
# Dir[pattern].each {|file| require file }

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, 'mysql://root@localhost/daitss2')

