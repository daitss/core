require 'AIPInPremis'
require 'db/aip'

DataMapper.setup(:aipstore, 'mysql://daitss:topdrawer@localhost/aip')

class AIPPolling
  repository(:aipstore) do
    @needWorkAIP = Aip.all(:needs_work => true) 
  end

  @needWorkAIP.each do |aip|
    begin
      repository(:default) do
        puts "processing #{aip.uri}"
        doc = XML::Document.string(aip.xml)
        doc.save('aip.xml', :indent => true, :encoding => LibXML::XML::Encoding::UTF_8)
        aipInPremis = AIPInPremis.new
        aipInPremis.process doc
      end
    rescue 
      puts "problem populating #{aip.uri}, daitss 2 dataase is not updated!"
    else #only update aip store after a successful daitss2 db population
      repository(:aipstore) do    
        aip.update(:needs_work => false)
      end
    end

    # sleep 5
  end
end

