require 'net/http'

require 'daitss/model/aip'
require 'daitss/proc/template/descriptor'
require 'daitss/proc/tempdir'

class Aip

  def Aip.new_from_wip wip
    aip = Aip.new
    aip.id = wip.id
    aip.uri = wip.uri
    aip.xml = wip['aip-descriptor']
    aip.copy_url, aip.copy_size, aip.copy_md5, aip.copy_sha1 = put_copy wip, "#{Daitss::CONFIG['storage']}/#{wip.id}-0"
    aip.datafile_count = wip.represented_datafiles.size

    unless aip.save
      delete_copy aip.copy_url
      mio = StringIO.new
      mio.puts "could not save aip: #{aip.errors.size} errors"
      aip.errors.each { |e| mio.puts e }
      raise mio.string
    end

    aip
  end

  def Aip.update_from_wip wip
    aip = Aip.get! wip.id
    aip.xml = wip['aip-descriptor']
    old_url = aip.copy_url.to_s
    old_suffix = old_url[/-(\d+)$/, 1]
    new_suffix = (old_suffix.to_i + 1).to_s
    aip.copy_url, aip.copy_size, aip.copy_md5, aip.copy_sha1 = put_copy wip, "#{Daitss::CONFIG['storage']}/#{wip.id}-#{new_suffix}"
    aip.datafile_count = wip.represented_datafiles.size

    if aip.save
      delete_copy old_url
    else
      delete_copy aip.copy_url
      mio = StringIO.new
      mio.puts "could not save aip: #{aip.errors.size} errors"
      aip.errors.each { |e| mio.puts e }
      raise mio.string
    end

    aip
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
        wip.represented_datafiles.each do |f|
          aip_path = File.join aip_dir, f['aip-path']
          FileUtils::mkdir_p File.dirname(aip_path)
          FileUtils::ln_s f.datapath, aip_path
        end

        descriptor_path = File.join(aip_dir, 'descriptor.xml')
        open(descriptor_path, 'w') { |io| io.write wip['aip-descriptor'] }

        xmlres_path = File.join(aip_dir, Wip::XML_RES_TARBALL)
        open(xmlres_path, 'w') { |io| io.write wip['xml-resolution-tarball'] }

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

        res = Net::HTTP.start(u.host, u.port) do |http|
          http.read_timeout = Daitss::CONFIG['http-timeout']
          http.request(req)
        end

        res.error! unless Net::HTTPCreated === res

        copy_spec = [url, size, md5, sha1]
      end

    end

    copy_spec
  end

end
