#!/usr/bin/env ruby

require 'dm-core'
require 'db/operations_agents'
require 'db/operations_events'
require 'db/accounts'
require 'db/projects'
require 'db/keys'
require 'digest/sha1'
require 'spec/helper.rb'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/submission_svc_test.db")
DataMapper.auto_migrate!

# adds an FDA account, and an Operator with credentials "operator", "operator"

a = add_account
o = add_operator a

