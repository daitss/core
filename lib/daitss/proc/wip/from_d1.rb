require 'daitss/proc/wip'
require 'daitss/proc/datafile/obsolete'
require 'digest/sha1'

module Daitss

  class Wip

    def load_from_d1_aip

      # need tb
      load_d1_datafiles

      # need descriptor
      load_d1_dmd
      load_sip_descriptor
      load_d1_package_digiprov
    end

    # SMELL this can go into a deterministic dmd section in the aip descriptor and be recycled
    # it wont change over time
    def load_d1_dmd

      title = self.package.intentity.title

      if title
        metadata['dmd-title'] = title
      end

      # volume
      volume = self.package.intentity.volume

      if volume
        metadata['dmd-volume'] = volume
      end

      # issue
      issue = self.package.intentity.issue

      if issue
        metadata['dmd-issue'] = issue
      end

      # issue
      issue = self.package.intentity.issue

      if issue
        metadata['dmd-issue'] = issue
      end

      # entity-id
      entity_id = self.package.intentity.entity_id

      if entity_id
        metadata['dmd-entity-id'] = entity_id
      end

    end

    # transfer datafiles into the wip
    def load_d1_datafiles
      doc = XML::Document.string self.package.aip.xml


      # unpack the tarball into a temp directory
      tdir = Dir.mktmpdir
      aip_dir = self.id
      tarball_file = "#{aip_dir}.tar"

      Dir.chdir tdir do
        # TODO get the url from randy's thing and put in data
        data = self.package.aip.copy.get_from_silo
        open(tarball_file, 'w') { |io| io.write data }
        %x{tar xf #{tarball_file}}
        raise "could not extract tarball: #{$?}" unless $?.exitstatus == 0
      end

      df_paths = self.package.intentity.datafiles.map do |dbdf|
        df_id = dbdf.id
        df = new_original_datafile df_id

        # copy over the datafile
        aip_path = dbdf.original_path
        tar_file = File.join tdir, aip_dir, aip_path
        FileUtils::cp tar_file, df.datapath

        # use d2 style aip-path
        aip_path = File.join AipArchive::SIP_FILES_DIR, dbdf.original_path

        # check the size
        expected_size = dbdf.size
        actual_size = df.size

        unless df.size == expected_size
          raise "datafile #{df.id} size is wrong: expected #{expected_size}, actual #{actual_size}"
        end

        # check the sha1
        # TODO sha1 is not migrated so we cant check. pass this by lydia
        lydia_says_so = false

        if lydia_says_so
          expected_sha1 = dbdf.message_digest.first(:code => 'SHA1').value
          actual_sha1 = df.open { |io| Digest::SHA1.hexdigest io.read }

          unless expected_sha1 == actual_sha1
            raise "datafile #{df.id} sha1 is wrong: expected #{expected_sha1}, actual #{actual_sha1}"
          end
        end

        df['aip-path'] = aip_path

      end

      # TODO create xml res tarballs
      unless File.directory? old_xml_res_tarball_dir
        FileUtils.mkdir old_xml_res_tarball_dir
      end

      pattern = File.join tdir, aip_dir, "#{XML_RES_TARBALL_BASENAME}-*.tar"

      Dir[pattern].each do |f|
        FileUtils.cp f, File.join(old_xml_res_tarball_dir, File.basename(f))
      end

      FileUtils.rm_r tdir
    end

    # transfer package wide events and agents
    def load_d1_package_digiprov
      es = PremisEvent.all(:relatedObjectId => self.package.id)
      metadata['old-digiprov-events'] = es.map { |e| e.to_premis_xml.to_s }.join "\n"

      as = es.map { |e| e.premis_agent }
      metadata['old-digiprov-agents'] = as.flatten.map { |a| a.to_premis_xml.to_s }.join "\n"
    end

  end

end
