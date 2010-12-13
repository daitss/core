require 'base64'
require 'curb'
require 'nokogiri'
require 'daitss/archive'

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

    RESERVE_PATH = '/reserve'


    # reserve a new location
    #
    # @param [String] package_id
    def RandyStore.reserve package_id
      c = Curl::Easy.http_post(archive.storage_url + RESERVE_PATH, Curl::PostField.content('ieid', package_id))
      xml = Nokogiri.XML(c.body_str) or raise("cannot parse response as XML")

      # check the response
      raise "bad status" unless (201...300).include? c.response_code
      raise "unknown document type" unless xml.root.name == 'reserved'
      raise "bad package id" unless xml.root['ieid'] == package_id
      raise "missing location" unless xml.root['location']
      raise "empty location" unless not xml.root['location'].empty?

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
      c = Curl::Easy.new @url
      c.follow_location = true
      c.http_get
      error!  unless c.response_code == 200
      c.body_str
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

      c = Curl::Easy.new @url
      c.headers['Content-MD5'] = Base64.encode64(md5.digest).strip
      c.headers['Content-Type'] = 'application/x-tar'
      c.http_put data
      xml = Nokogiri.XML(c.body_str) or res.error!("cannot parse response as XML")

      # check the response
      raise "bad status" unless (201...300).include? c.response_code
      raise "unknown document type" unless xml.root.name == 'created'
      raise "bad package id" unless xml.root['ieid'] == @package_id
      raise "bad location" unless xml.root['location'] == @url
      raise "bad sha1" unless xml.root['sha1'] == sha1.hexdigest
      raise "bad md5" unless xml.root['md5'] == md5.hexdigest
      raise "bad size" unless xml.root['size'].to_i == data.size

      # return some info about the put
      {
        :size => xml.root['size'].to_i,
        :sha1 => xml.root['sha1'],
        :md5 => xml.root['md5'],
        :url => @url
      }
    end

    # put the data to this resource
    #
    # @param [String] path to file to send
    def put_file path
      md5, sha1 = calc_digests path, Digest::MD5, Digest::SHA1

      headers = {
        'Content-MD5' => Base64.encode64(md5.digest).strip,
        'Content-Type' => 'application/x-tar',
      }

      c = Curl::Easy.new @url
      c.headers['Content-MD5'] = Base64.encode64(md5.digest).strip
      c.headers['Content-Type'] = 'application/x-tar'
      c.http_put open(path)
      xml = Nokogiri.XML(c.body_str) or raise("cannot parse response as XML")

      # check the response
      raise "bad status" unless (201...300).include? c.response_code
      raise "unknown document type" unless xml.root.name == 'created'
      raise "bad package id" unless xml.root['ieid'] == @package_id
      raise "bad location" unless xml.root['location'] == @url
      raise "bad sha1" unless xml.root['sha1'] == sha1.hexdigest
      raise "bad md5" unless xml.root['md5'] == md5.hexdigest
      raise "bad size" unless xml.root['size'].to_i == File.size(path)

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
      c = Curl::Easy.http_delete @url
      raise "bad status" unless [200, 202, 204].include? c.response_code
    end

    def head
      c = Curl::Easy.http_head @url
      raise "bad status" unless [200, 202, 204].include? c.response_code
    end

    private

    def calc_digests path, *klasses
      buf_size = (1024 ** 2) * 8
      buf = String.new
      digests = klasses.map &:new

      open(path) do |io|

        while io.read(buf_size, buf)
          digests.each { |d| d.update buf }
        end

      end

      digests
    end

  end

end
