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
      raw = template_by_name('transformation_event').result(binding)
      XML::Parser.string(raw).parse
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