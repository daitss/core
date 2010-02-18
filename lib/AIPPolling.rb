require 'AIPInPremis'
require 'db/aip'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:aipstore, 'mysql://root@localhost/aip')

class AIPPolling
  repository(:aipstore) do
    @needWorkAIP = Aip.all(:needs_work => true) 
  end
  
  repository(:default) do
    @needWorkAIP.each do |aip|
      puts aip
      aip.xml
      aipInPremis = AIPInPremis.new
      aipInPremis.process aip.xml
    end
  end
end

