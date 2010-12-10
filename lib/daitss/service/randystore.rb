require 'base64'
require 'typhoeus'
require 'nokogiri'

class Typhoeus::Response

    def error! message=nil
      req = self.request
      msg = StringIO.new
      msg.puts message if message
      msg.puts "#{req.method.to_s.upcase} #{self.request.url} => #{self.code}"
      msg.puts body if body
      raise msg.string
    end

end

# OSX SHA1 bug
if PLATFORM =~ /darwin/

  class Digest::SHA1

    def update s
      buf_size = (1024 ** 2) * 256

      if s.size > buf_size
        io = StringIO.new s
        buf = String.new
        super buf while io.read(buf_size, buf)
      else
        super s
      end

    end

  end

end

module Daitss

  class RandyStore

    # reserve a new location
    #
    # @param [String] package_id
    def RandyStore.reserve package_id
      res = Typhoeus::Request.post "#{archive.storage_url}/reserve", :params => { :ieid => package_id }
      xml = Nokogiri.XML(res.body) or res.error!("cannot parse response as XML")

      # check the response
      res.error! "bad status" unless (201...300).include? res.code
      res.error! "unknown document type" unless xml.root.name == 'reserved'
      res.error! "bad package id" unless xml.root['ieid'] == package_id
      res.error! "missing location" unless xml.root['location']
      res.error! "empty location" unless not xml.root['location'].empty?

      # return a new resource object
      RandyStore.new package_id, xml.root['location']
    end

    attr_reader :package_id, :url

    # @param [String] package_id
    # @param [String] url
    def initialize package_id, url
      @package_id = package_id
      @url = url
    end

    # get the data from this resource
    #
    # @return [String] tarball data
    def get
      res = Typhoeus::Request.get @url, :follow_location => true
      res.error! unless 200 == res.code
      res.body
    end

    # put the data to this resource
    #
    # @param [String] data to send
    def put data
      md5 = Digest::MD5.new
      sha1 = Digest::SHA1.new
      [md5, sha1].each { |md| md.update data }

      headers = {
        'Content-MD5' => Base64.encode64(md5.digest).strip,
        'Content-Type' => 'application/x-tar',
      }

      res = Typhoeus::Request.put @url, :headers => headers, :body => data
      xml = Nokogiri.XML(res.body) or res.error!("cannot parse response as XML")

      # check the response
      res.error! "bad status" unless (201...300).include? res.code
      res.error! "unknown document type" unless xml.root.name == 'created'
      res.error! "bad package id" unless xml.root['ieid'] == @package_id
      res.error! "bad location" unless xml.root['location'] == @url

      res.error! "bad sha1" unless xml.root['sha1'] == sha1.hexdigest
      res.error! "bad md5" unless xml.root['md5'] == md5.hexdigest
      res.error! "bad size" unless xml.root['size'].to_i == data.size

      # return some info about the put
      {
        :size => xml.root['size'].to_i,
        :sha1 => xml.root['sha1'],
        :md5 => xml.root['md5'],
        :url => @url
      }
    end

    # delete the data from this resource
    def delete
      res = Typhoeus::Request.delete @url
      res.error! unless [200, 202, 204].include? res.code
    end

    def head
      res = Typhoeus::Request.head @url
      res.error! unless [200, 202, 204].include? res.code
    end

  end

end
