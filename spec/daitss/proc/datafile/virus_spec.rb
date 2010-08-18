require 'daitss/proc/datafile/virus'
require 'spec_helper'

describe DataFile do

  before :all do
    @wip = submit 'mimi'
    @df = @wip.original_datafiles.last
    @df.virus_check!
  end

  it 'should return a premis event' do
    doc = XML::Document.string @df['virus-check-event']
    doc.find("//P:event/P:eventType = 'virus check'", NS_PREFIX).should be_true
  end

  it 'should return a premis agent' do
    doc = XML::Document.string @df['virus-check-event']
    agent_id = doc.find_first("//P:event[P:eventType = 'virus check']/P:linkingAgentIdentifier/P:linkingAgentIdentifierValue", NS_PREFIX).content

    doc = XML::Document.string @df['virus-check-agent']
    doc.find("//P:agent/P:agentIdentifier/P:agentIdentifierValue = '#{agent_id}'", NS_PREFIX).should be_true
  end

end
