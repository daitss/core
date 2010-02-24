require 'AIPInPremis'
require 'db/aip'

DataMapper.setup(:aipstore, 'mysql://daitss:topdrawer@localhost/aip')

class AIPPolling
  repository(:aipstore) do
    @needWorkAIP = Aip.all(:needs_work => true) 
  end
  
  repository(:default) do
    @needWorkAIP.each do |aip|
      doc = XML::Document.string(aip.xml)
      doc.save('aip.xml', :indent => true, :encoding => LibXML::XML::Encoding::UTF_8)
      aipInPremis = AIPInPremis.new
      aipInPremis.process doc
    end
  end
end

