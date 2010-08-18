require 'dm-core'


DataMapper.setup(:default, "sqlite3://#{File.dirname(__FILE__)}/data/submission_svc_test.db")

