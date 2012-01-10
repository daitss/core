require 'base64'
require 'curb'
require 'daitss/archive'
require 'mixin/curb'
require 'mixin/digest'
require 'nokogiri'

module Daitss

  class StorageMaster

    RESERVE_PATH = '/reserve'

    # reserve a new location
    #
    # @param [String] package_id
    def StorageMaster.reserve package_id
      c = Curl::Easy.http_post(archive.storage_url + RESERVE_PATH, Curl::PostField.content('ieid', package_id))
      (200..201).include? c.response_code or c.error("bad status")

      # check the response
      xml = Nokogiri.XML(c.body_str) or c.error("cannot parse response as XML")
      xml.root.name == 'reserved' or c.error("unknown document type")
      xml.root['ieid'] == package_id or c.error("bad package id")
      xml.root['location'] or c.error("missing location")
      not xml.root['location'].empty? or  c.error("empty location")

      # return a new resource object
      StorageMaster.new package_id, xml.root['location']
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
      c.error "bad status" unless c.response_code == 200
      c.body_str
    end

    # get the data from this resource into a file
    #
    # @param [String] f file to download to
    # @return [String] tarball data
    def download f

      Datyl::Logger.info "Beginning AIP download for #{f}"

      c = Curl::Easy.download(@url, f) do |c|
        c.follow_location = true
        c.timeout = Archive.instance.storage_download_timeout
      end

      c.error "bad status" unless c.response_code == 200
      Datyl::Logger.info "AIP download for #{f} complete"
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
      (201...300).include? c.response_code or c.error("bad status")
      xml.root.name == 'created' or c.error("unknown document type")
      xml.root['ieid'] == @package_id or c.error("bad package id")
      xml.root['location'] == @url or c.error("bad location")
      xml.root['sha1'] == sha1.hexdigest or c.error("bad sha1")
      xml.root['md5'] == md5.hexdigest or c.error("bad md5")
      xml.root['size'].to_i == data.size or c.error("bad size")

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
      (201...300).include? c.response_code or c.error("bad status")
      xml.root.name == 'created' or c.error("unknown document type")
      xml.root['ieid'] == @package_id or c.error("bad package id")
      xml.root['location'] == @url or c.error("bad location")
      xml.root['sha1'] == sha1.hexdigest or c.error("bad sha1")
      xml.root['md5'] == md5.hexdigest or c.error("bad md5")
      xml.root['size'].to_i == File.size(path) or c.error("bad size")

      # return some info about the put
      {
        :size => xml.root['size'].to_i,
        :sha1 => xml.root['sha1'],
        :md5 => xml.root['md5'],
        :url => @url,
        :timestamp => Time.now
      }
    end

    # delete the data from this resource
    def delete
      c = Curl::Easy.http_delete @url
      c.error("bad status") unless [200, 202, 204, 207, 410].include? c.response_code
    end

    def head
      c = Curl::Easy.http_head @url
      c.error("bad status") unless c.response_code == 200
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
