require 'template'
require 'service/error'

module Service
  
  module Transform
  
    class Transformation
    
      attr_reader :url, :src
    
      def initialize url, src
        @url = url
        @src = src
      end
    
      # Perform the transformation via the service
      def perform!
        s_url = "#{@url}?location=#{CGI::escape @src.url.to_s}"
      
        response = Net::HTTP.get_response URI.parse(s_url)
        xform_doc = case response
                    when Net::HTTPSuccess
                      XML::Parser.string(response.body).parse
                    else
                      raise ServiceError, "cannot perform transformation: #{response.code} #{response.msg}: #{response.body}"
                    end
      
        @links = xform_doc.find('/links/link').map do |node| 
          relative_url = node.content.strip
          URI.join(s_url, relative_url).to_s
        end
      
      end

      # Return a yield io objects to this new data
      def data
        @links.each do |link|
          fname = File.basename URI.parse(link).path
          open(link) { |io| yield io, fname }
        end
      
      end

      # Return a PREMIS document describing the transformation (the new file)
      def metadata(files)
        event_id = next_event_id_index(files)
        raw = template_by_name('transformation_event').result(binding)
        XML::Parser.string(raw).parse
      end
    
      def to_s
        @url
      end
    
      private
      
      def next_event_id_index(files)

         event_ids = files.inject([]) do |acc,f|

           l = f.md_for(:digiprov).map do |doc|
             xpath = "//premis:event/premis:eventIdentifier[premis:eventIdentifierType = 'd2']/premis:eventIdentifierValue"
             doc.find(xpath, NS_MAP).map { |e| e.content.strip }
           end

           acc + l.flatten            
         end

         event_ids.next_in %r{event-(\d+)}
       end
       
    end
  
    class Migration < Transformation; end
  
    class Normalization < Transformation; end
  
    # Return a list of transformation URL
    def transformations
      type = "Action Plan Determination"

      ap_doc = md_for(:digiprov).find do |doc|
        doc.find_first("//premis:event[premis:eventType = '#{type}']", NS_MAP)
      end

      if ap_doc    
        ap_event = ap_doc.find_first("//premis:event[premis:eventType = '#{type}']", NS_MAP)

        ap_event.find("//premis:eventOutcomeDetailExtension/*[premis:transformation]", NS_MAP).map do |node|
          t_url = node.find_first("premis:transformation", NS_MAP).content.strip

          case node.name
          when 'migration'
            Migration.new t_url, self

          when 'normalization'
            Normalization.new t_url, self
          else
            raise "unknown transformation type #{node.name}"
          end

        end
      
      else
        []
      end
        
    end
      
  end

end