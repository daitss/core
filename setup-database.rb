#!/usr/bin/env ruby

require 'dm-core'
require 'db/operations_agents'
require 'db/operations_events'
require 'db/projects'
require 'db/accounts'
require 'db/keys'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/daitss-core.db")

DataMapper.auto_migrate!
