require 'open-uri'
require 'cgi'

class Event
  attr_accessor :action
end

class Aip

  def initialize(archive, path)
    @archive = archive
    @path = path
  end

  def url
    "#{@archive.url}/#{@path}"
  end

  def ingest
    validate if !rejected? && !validated?
  end

  def validate
    
    # TODO make a restful interface for this
    doc = open("http://server/validate/location=#{CGI::escape(url)}") do |r|
      code, message = r.status

      case code.to_i
      when 200
        Nokogiri::XML r
      when (400...500)
        raise "client error: #{code} #{message}"
      when (500...600)
        raise "server error: #{code} #{message}"
      end

    end

    valid = doc.xpath("/validity/@outcome").find do |n|
      case n.content
      when /yes/i
        true
      when /no/i
        false
      else
        raise "unexpected validitity outcome #{n.content}"
      end

    end

    add_validity_info raw
    add_event 'valid'
  end
  
  # Adds a validity info document to this aip
  def add_validity_info
    # TODO as events?
  end
  
  # Adds a new event to this aip
  def add_event(action)
    t = Time.now
    # TODO
  end
  
  # Returns true if the aip has a validation event
  def validated?
    events.any? { |e| e.action == 'validation' }
  end

  # Returns true if the aip has a rejection event
  def rejected?
    events.any? { |e| e.action == 'rejection' }
  end

  def events
    e = Event.new
    e.action = "package validation"
    [ e ]
  end

  def exist?
    response = @archive.get "/archive/#{@path}"

    case response
    when Net::HTTPNotFound
      false
    when Net::HTTPSuccess
      true
    else
      raise "server returned #{response.value}"
    end

  end

end
