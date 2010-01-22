require 'dm-core'
require 'dm-types'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/submissions.db")

class Submission
  include DataMapper::Resource

   property :package_name, String, :nullable => false
   property :ieid, String, :nullable => false, :key => true
   property :submission_checksum, String, :nullable => false
   property :timestamp, DateTime, :nullable => false
   property :submitter_ip, IPAddress, :nullable => false
end

