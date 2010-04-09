require 'AIPInPremis'
require 'aip'

class AIPPolling

  def populate
    # repository(:default) do
    #    aipInPremis = AIPInPremis.new
    #    aipInPremis.processAIPFile "aip.xml"
    #  end

    #gathering all aips that need to be populated to daitss2 fast access database
    # repository(:aipstore) do
    @needWorkAIP = Aip.all(:needs_work => true)
    # @doc = XML::Document.string(@needWorkAIP.xml)
    # end


    @needWorkAIP.each do |aip|
      begin
        # repository(:default) do
        puts "processing #{aip.uri}"
        doc = XML::Document.string(aip.xml)
        doc.save('aip.xml', :indent => true, :encoding => LibXML::XML::Encoding::UTF_8)
        aipInPremis = AIPInPremis.new
        aipInPremis.process doc
        # end
      rescue => e
        puts e.message
        puts e.backtrace
        puts "problem populating #{aip.uri}, daitss 2 database is not updated!"
      else # only update aip store after a successful daitss2 fast access db population
        # repository(:aipstore) do
        aip.update!(:needs_work => false)
        # end
      end
    end

  end
end
