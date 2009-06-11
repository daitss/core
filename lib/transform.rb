module Transform
  
  class Transformation
    
    attr_reader :url, :src
    
    def initialize url, src
      @url = url
      @src = src
    end
    
    # Perform the transformation via the service
    def perform!
      s_url = "#{@url}/?location=#{CGI::escape @src.url}"
      xform_doc = open(s_url) { |resp| XML::Parser.io(resp).parse }
      @links = xform_doc.find('/links/link').map { |node| node.contents.strip }
    end

    # Return a yield io objects to this new data
    def data
      
      @links.each do |link|
        open(link) { |io| yield io }
      end
      
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

    ap_doc = md_for(:digiprov).find do |doc|
      doc.find_first("//premis:event[premis:eventType[normalize-space(.)='#{type}']]", NS_MAP)
    end
    
    ap_event = ap_doc.find_first("//premis:event[premis:eventType[normalize-space(.)='#{type}']]", NS_MAP)
    
    puts ap_event
    
    ap_event.find("//premis:eventOutcomeDetailExtension/*[premis:transformation]", NS_MAP).map do |node|
      t_url = node.find_first("premis:transformation").contents.strip
      
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