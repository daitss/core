module Transform
  
  class Transformation
    
    attr_reader :url, :src
    
    def initialize url, src
      @url = url
      @src = src
    end
    
    # Perform the transformation via the service
    def perform!
    end

    # Return an io object to this new data
    def data
      StringIO.new 'everything is converted to plain text!'
    end

    # Return a PREMIS document describing the transformation (the new file)
    def metadata
      XML::Parser.string(<<PREMIS).parse
<premis xmlns="info:lc/xmlns/premis-v2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0">
	<event>
		<eventIdentifier>
			<eventIdentifierType>Temporary Local</eventIdentifierType>
			<eventIdentifierValue>1</eventIdentifierValue>
		</eventIdentifier>
		<eventType>#{self.class}</eventType>
		<eventDateTime>#{Time.now}</eventDateTime>
		<eventOutcomeInformation>
			<eventOutcome>success</eventOutcome>
			<eventOutcomeDetail>
				<eventOutcomeDetailNote>
				Transformed via #{url}
				</eventOutcomeDetailNote>
			</eventOutcomeDetail>
		</eventOutcomeInformation>
		<linkingObjectIdentifier>
      <linkingObjectIdentifierType>URI</linkingObjectIdentifierType>
      <linkingObjectIdentifierValue>#{src.url}</linkingObjectIdentifierValue>
    </linkingObjectIdentifier>
    <linkingAgentIdentifier>
      <linkingAgentIdentifierType>Temporary Local</linkingAgentIdentifierType>
      <linkingAgentIdentifierValue>2</linkingAgentIdentifierValue>
    </linkingAgentIdentifier>
	</event>
	
	<agent>
    <agentIdentifier>
      <agentIdentifierType>Temporary Local</agentIdentifierType>
      <agentIdentifierValue>2</agentIdentifierValue>
    </agentIdentifier>
    <agentName>Transformation Service</agentName>
    <agentType>Web Service</agentType>
  </agent>
  
</premis>
PREMIS
      # TODO produce 
    end
    
  end
  
  class Migration < Transformation
  end
  
  class Normalization < Transformation
  end
  
  # Return a list of transformation URL
  def transformations
    type = "Action Plan Determination"

    ap_event = md_for(:digiprov).first do |doc|
      doc.find_first("//premis:event[premis:eventType[normalize-space(.)='#{type}']]", NS_MAP)
    end
    
    ap_event.find("//premis:eventOutcomeDetailExtension/*[transformation]", NS_MAP).map do |node|
      t_url = node.find_first("transformation").contents.strip
      
      case node.contents.strip
      when 'migration'
        Migration.new t_url, self
        
      when 'normalization'
        Normalization.new t_url, self
        
      end
      
    end
    
  end
  
  def transform
  end
      
end