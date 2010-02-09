require 'net/http'
require 'db/aip'
require 'descriptor'
require 'wip/representation'
require 'tempdir'

class Aip

  def Aip.new_from_wip wip
    aip = Aip.new
    aip.id = wip.id
    aip.uri = wip.uri
    aip.xml = wip.descriptor.to_s
    aip.copy_url, aip.copy_size, aip.copy_md5, aip.copy_sha1 = put_copy wip, "#{CONFIG['storage-url']}/#{wip.id}"
    aip.needs_work = true

    unless aip.save 
      delete_copy aip.copy_url
      aip.errors.each { |e| puts e }
      raise "could not save aip: #{aip.errors.size}"
    end

  end

  def Aip.update_from_wip wip
    aip = Aip.get! wip.id
  end

  private

  def Aip.delete_copy url
    u = ::URI.parse url
    req = Net::HTTP::Delete.new u.path
    res = Net::HTTP.start(u.host, u.port) { |http| http.request(req) }
    res.error! unless Net::HTTPSuccess === res
  end

  def Aip.put_copy wip, url

    copy_spec = nil

    Tempdir.new do |dir|

      Dir::chdir(dir.path) do
        aip_dir = wip.id
        tarball_file = "#{aip_dir}.tar"

        # make a directory representation of the aip
        FileUtils::mkdir aip_dir
        wip.represented_files.each do |f|
          sip_path = File.join aip_dir, (f['sip-path'] or f['aip-path'])
          FileUtils::mkdir_p File.dirname(sip_path)
          FileUtils::ln_s f.datapath, sip_path
        end

        descriptor_path = File.join(aip_dir, 'descriptor.xml')
        open(descriptor_path, 'w') { |io| io.write wip['aip-descriptor'] }

        # tar it up
        %x{tar --dereference --create --file #{tarball_file} #{aip_dir}}
        raise "could not make tarball: #{$?}" unless $?.exitstatus == 0

        # record info
        sha1 = open(tarball_file) { |io| Digest::SHA1.hexdigest io.read }
        md5 = open(tarball_file) { |io| Digest::MD5.hexdigest io.read }
        size = File::size tarball_file

        # put the tarball
        u = ::URI.parse url
        req = Net::HTTP::Put.new u.path
        req.content_type = 'application/tar'
        req.content_length = size
        req['content-md5'] = md5
        req.body_stream = open(tarball_file)
        res = Net::HTTP.start(u.host, u.port) { |http| http.request(req) }
        res.error! unless Net::HTTPCreated === res

        copy_spec = [url, size, md5, sha1]
      end

    end

    copy_spec
  end

end
