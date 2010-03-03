require 'AIPInPremis'
require 'db/aip'

DataMapper.setup(:aipstore, 'mysql://daitss:topdrawer@localhost/aip')

class AIPPolling
  # gathering all aips that need to be populated to daitss2 fast access database
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
    else #only update aip store after a successful daitss2 fast access db population
      repository(:aipstore) do    
        puts aip.inspect
        aip.update!(:needs_work => false)
      end
    end
  end
end

