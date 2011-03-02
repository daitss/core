module Daitss

  class Wip
    DESCRIPTOR_FILE = "descriptor.xml"
    SIP_FILES_DIR = 'sip-files'
    AIP_FILES_DIR = 'aip-files'
    XML_RES_TARBALL_BASENAME = 'xmlres'

    def make_tarball

      # copy and link files into an aip dir
      temp_dir = Dir.mktmpdir
      aip_dir = id

      Dir.chdir temp_dir do

        FileUtils.mkdir aip_dir

        # link in datafiles
        represented_datafiles.each do |f|
          aip_path = File.join aip_dir, f['aip-path']

          unless File.exist?(aip_path) and Digest::MD5.file(aip_path).hexdigest == Digest::MD5.file(f.data_file).hexdigest
            FileUtils.mkdir_p File.dirname(aip_path) unless File.exist? File.dirname(aip_path)
            FileUtils.ln_s f.data_file, aip_path
          end

        end

        # link in old xmlres tarballs
        old_xml_res_tarballs.each do |f|
          FileUtils.ln_s f, File.join(aip_dir, File.basename(f))
        end

        # link in current xmlres tarball
        n = next_xml_res_tarball_index
        xmlres_path = File.join(aip_dir, "#{Wip::XML_RES_TARBALL_BASENAME}-#{n}.tar")
        FileUtils.ln_s xmlres_file, xmlres_path

        # link in xml descriptor
        descriptor_path = File.join(aip_dir, DESCRIPTOR_FILE)
        FileUtils.ln_s aip_descriptor_file, descriptor_path

        # tar up the aip
        %x{tar --dereference --create --file #{tarball_file} #{aip_dir}}
        raise "could not make tarball: #{$?}" unless $?.exitstatus == 0
      end

    ensure
      FileUtils.rm_r temp_dir
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
