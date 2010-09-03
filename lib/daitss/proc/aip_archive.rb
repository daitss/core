require 'digest/md5'
require 'digest/sha1'

class AipArchive

  SIP_FILES_DIR = 'sip-files'
  AIP_FILES_DIR = 'aip-files'

  attr_reader :size, :sha1, :md5

  def initialize wip
    @tdir = Dir.mktmpdir
    @wip = wip
    @aip_dir = wip.id
    @tarball_file = "#{@aip_dir}.tar"

    make_fs_layout
    make_tarball
    extract_data

    if block_given?
      yield self
      cleanup
    end

  end

  def extract_data
    @md5 = Digest::MD5.file(tarball_path).hexdigest
    @sha1 = Digest::SHA1.file(tarball_path).hexdigest
    @size = File.size tarball_path
  end

  def tarball_path
    File.join @tdir, @tarball_file
  end

  def cleanup
    FileUtils.rm_r @tdir
  end

  def open

    if block_given?
      Kernel.open tarball_path { |io| yield io }
    else
      Kernel.open tarball_path
    end

  end

  private

  def make_fs_layout

    Dir.chdir @tdir do
      FileUtils.mkdir @aip_dir

      # copy in datafiles
      @wip.represented_datafiles.each do |f|
        aip_path = File.join @aip_dir, f['aip-path']
        FileUtils.mkdir_p File.dirname(aip_path)
        FileUtils.ln_s f.datapath, aip_path
      end

      # copy in old xmlres tarballs
      @wip.old_xml_res_tarballs.each do |f|
        FileUtils.ln_s f, File.join(@aip_dir, File.basename(f))
      end

      # copy in current xmlres tarball
      n = next_xml_res_tarball_index
      xmlres_path = File.join(@aip_dir, "#{Wip::XML_RES_TARBALL_BASENAME}-#{n}.tar")
      Kernel.open(xmlres_path, 'w') { |io| io.write @wip['xml-resolution-tarball'] }

      # copy in xml descriptor
      descriptor_path = File.join(@aip_dir, 'descriptor.xml')
      Kernel.open(descriptor_path, 'w') { |io| io.write @wip['aip-descriptor'] }
    end

  end

  def next_xml_res_tarball_index
    ts = @wip.old_xml_res_tarballs

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

  def make_tarball

    Dir.chdir @tdir do
      %x{tar --dereference --create --file #{@tarball_file} #{@aip_dir}}
      raise "could not make tarball: #{$?}" unless $?.exitstatus == 0
    end

  end

end
