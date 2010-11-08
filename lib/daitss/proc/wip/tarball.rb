require 'digest/sha1'
require 'digest/md5'

module Daitss

  class Wip

    def tarball_file
      File.join @path, "#{id}.tar"
    end

    def tarball_sha1
      Digest::SHA1.file(tarball_file).hexdigest
    end

    def tarball_md5
      Digest::MD5.file(tarball_file).hexdigest
    end

    def tarball_size
      File.size tarball_file
    end

    def make_tarball

      # copy and link files into an aip dir
      temp_dir = Dir.mktmpdir
      aip_dir = id

      Dir.chdir temp_dir do

        FileUtils.mkdir aip_dir

        # link in datafiles
        represented_datafiles.each do |f|
          aip_path = File.join aip_dir, f['aip-path']

          unless File.exist?(aip_path) and Digest::MD5.file(aip_path).hexdigest == Digest::MD5.file(f.datapath).hexdigest
            FileUtils.mkdir_p File.dirname(aip_path) unless File.exist? File.dirname(aip_path)
            FileUtils.ln_s f.datapath, aip_path
          end

        end

        # link in old xmlres tarballs
        old_xml_res_tarballs.each do |f|
          FileUtils.ln_s f, File.join(aip_dir, File.basename(f))
        end

        # copy in current xmlres tarball
        n = next_xml_res_tarball_index
        xmlres_path = File.join(aip_dir, "#{Wip::XML_RES_TARBALL_BASENAME}-#{n}.tar")
        Kernel.open(xmlres_path, 'w') { |io| io.write metadata['xml-resolution-tarball'] }

        # copy in xml descriptor
        descriptor_path = File.join(aip_dir, 'descriptor.xml')
        Kernel.open(descriptor_path, 'w') { |io| io.write metadata['aip-descriptor'] }

        # tar up the aip
        %x{tar --dereference --create --file #{tarball_file} #{aip_dir}}
        raise "could not make tarball: #{$?}" unless $?.exitstatus == 0
      end

    end

    def next_xml_res_tarball_index
      ts = old_xml_res_tarballs

      if ts.empty?
        0
      else
        old_indices = ts.map do |f|

          if f =~ %r{#{Wip::XML_RES_TARBALL_BASENAME}-(\d+).tar$}
            $1.to_i
          else
            raise "old xmlres tarball has bad name: #{f}"
          end

        end

        old_indices.max + 1
      end

    end

  end

end
