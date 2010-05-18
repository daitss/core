require 'base64'
require 'datafile'

class DataFile

  def virus_check!
    output = %x{curl -s -d 'data=@#{self.datapath}' #{Daitss::CONFIG['viruscheck-url']}}
    raise "could not request virus check: #{output}" unless $?.exitstatus == 0
    doc = XML::Document.string output
    extract_event doc
    extract_agent doc
  end

  def extract_event doc
    event = doc.find_first("//P:event", NS_PREFIX)
    event.find_first("//P:linkingObjectIdentifierValue", NS_PREFIX).content = uri
    event.find_first("//P:eventIdentifierValue", NS_PREFIX).content = "#{uri}/event/virus-check"
    e_doc = XML::Document.new
    e_doc.root = e_doc.import event
    metadata['virus-check-event'] = e_doc.root.to_s
  end

  def extract_agent doc
    agent = doc.find_first("//P:agent", NS_PREFIX)
    a_doc = XML::Document.new
    a_doc.root = a_doc.import agent
    metadata['virus-check-agent'] = a_doc.root.to_s
  end

end
