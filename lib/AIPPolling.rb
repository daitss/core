require 'AIPInPremis'
require 'db/aip'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:aip, 'mysql://root@localhost/aip')

class AIPPolling
  
end

