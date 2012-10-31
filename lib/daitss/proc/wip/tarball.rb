module Daitss

  class Wip
    DESCRIPTOR_FILE = "descriptor.xml"
    SIP_FILES_DIR = 'sip-files'
    AIP_FILES_DIR = 'aip-files'
    XML_RES_TARBALL_BASENAME = 'xmlres'

    def make_tarball
      n = next_xml_res_tarball_index
      container = XML_RES_TARBALL_BASENAME + '-' + "#{n}"
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

	# issue core #445
        # link in old xmlres tarballs
	# but first expand the tarballs in a container directory named with tarball basename
	# e.g  xmlres-0.tar  is expanded to  a directory xmlres-0.
	# then rearchive into    xmlres-0 direcrtory.
	# purpose is to ensure expansions do not overwrite each other.
	# equivalent of:
	#  1.  mkdir xmlres-1 
	#  2.  tar -xf xmlres-1.tar -C xmlres-1
	cwd  = `pwd`.chomp
        old_xml_res_tarballs.each do |f|
        container = File.basename(f)
	container=container.chomp(File.extname(container) ).chomp
         #tar_temp_dir  = Dir.mktmpdir
         Dir.mktmpdir do |tar_temp_dir|  
	   Dir.chdir tar_temp_dir  # raises  warning: conflicting chdir during another chdir block
	   %x{tar -xf #{f}}
           raise "could not expand tarball=#{f} into dir= #{tar_temp_dir}: #{$?}" unless $?.exitstatus == 0
	   if not File.exists? container 
		   Dir.mkdir container
		   raise "could not make dir #{container} when sitting in dir #{tar_temp_dir} rc: #{$?}" unless $?.exitstatus == 0
		   %x{mv #{aip_dir} #{container}}
		   raise "could not move aip_dir #{aip_dir} into dir #{container} when sitting in dir #{tar_temp_dir} rc: #{$?}" unless $?.exitstatus == 0
	   end
	   %x{tar -cf #{f} #{container}}
           raise "could not make   tarball=#{f} from dir #{container} rc: #{$?}" unless $?.exitstatus == 0
	   Dir.chdir(cwd)   # raises  warning: conflicting chdir during another chdir block
          FileUtils.ln_s f, File.join(aip_dir, File.basename(f))
	 end
        end

        # link in current xmlres tarball
        #n = next_xml_res_tarball_index
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
