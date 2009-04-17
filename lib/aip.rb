require 'open-uri'
require 'cgi'

module Daitss

  class Event
    attr_accessor :action
  end

  class Aip

    def initialize(archive, name)
      @archive = archive
      @name = name
    end

    # operations on this resource

    def get
      response = @archive.get "/archive/#{name}"
      Nokogiri::XML response.body
    end

    def delete
      @archive.delete "/archive/#{name}"
    end

    # sub resources

    def events
      response = @archive.get "/archive/#{@name}/events"
      doc = Nokogiri::XML response.body
      doc.xpath("/events/event/@id").map { |eid| Event.new self, eid.content }
    end

    def existing_files
      response = @archive.get "/archive/#{name}/representations/1"
      doc = Nokogiri::XML response.body
      doc.xpath("/files/file/@id").map { |fid| Daitss::File.new self, fid.content }
    end

    def new_files
      response = @archive.get "/archive/#{name}/representations/1"
      doc = Nokogiri::XML response.body
      doc.xpath("/files/file/@id").map { |fid| Daitss::File.new self, fid.content }
    end

    # Ingest this aip
    def ingest
      
      # validation
      validate if !rejected? && !validated?

      # process each existing file
      existing_files.each do |file|
        file.process
      end

      # process each produced file
      new_files.each do |file|
        file.process
      end

    end

    # Validate this aip against a AIP service
    def validate

      # TODO configuration variable
      url = "http://#{@archive.host}:#{@archive.port}/archive/#{@name}"
      doc = open("http://localhost:3003/validity/location=#{CGI::escape(url)}") do |r|
        code, message = r.status
        case code.to_i
        when 200
          raise "empty entity" if r.string.empty?
          Nokogiri::XML r
        when (400...500)
          raise "client error: #{code} #{message}"
        when (500...600)
          raise "server error: #{code} #{message}"
        end

      end
      
      valid = doc.xpath("/validity/@outcome").find do |n|
        
        case n.content
        when "pass"
          true
        when "fail"
          false
        else
          raise "unexpected validitity outcome \"#{n.content}\""
        end

      end

      add_validity_info #doc
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

  end

end
