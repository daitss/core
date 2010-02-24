require 'AIPInPremis'
require 'db/aip'

DataMapper.setup(:aipstore, 'mysql://daitss:topdrawer@localhost/aip')

class AIPPolling
  repository(:aipstore) do
    @needWorkAIP = Aip.all(:needs_work => true) 
  end
  
  repository(:default) do
    @needWorkAIP.each do |aip|
      puts aip
      puts aip.xml
      aipInPremis = AIPInPremis.new
      aipInPremis.process XML::Document.string(aip.xml)
    end
  end
end

