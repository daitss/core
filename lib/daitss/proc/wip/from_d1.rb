require 'daitss/proc/wip'
require 'daitss/proc/wip/tarball'
require 'daitss/proc/datafile/obsolete'
require 'digest/sha1'

module Daitss

  class Wip

    def load_from_d1_aip

      # need tb
      step('load legacy package') { load_d1_datafiles }

      # need descriptor
      step('extract legacy metadata') do
        load_d1_dmd
        load_sip_descriptor
        load_d1_package_digiprov
      end

      # restore duplicates deleted by d1
      step('restore dedupep files') { restore_deleted_duplicates }

      # bring in global tar into xmlres-0
      step('compile legacy globals to xmlres') { compile_globals }
    end

    def load_d1_dmd
      metadata["dmd-account"] = self.package.project.account.id
      metadata["dmd-project"] = self.package.project.id
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
        package.aip.copy.download tarball_file
        %x{tar xf #{tarball_file}}
        raise "could not extract tarball: #{$?}" unless $?.exitstatus == 0
      end


      Datyl::Logger.info "Creating wip from tar for #{id}"

      df_paths = self.package.intentity.datafiles.map do |dbdf|
        df_id = dbdf.id
        df = new_original_datafile df_id

        # copy over the datafile
        aip_path = dbdf.original_path
        tar_file = File.join tdir, aip_dir, aip_path
        FileUtils::cp tar_file, df.data_file

        # use d2 style aip-path
        aip_path = File.join Wip::SIP_FILES_DIR, dbdf.original_path

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

        df['sip-path'] = dbdf.original_path
        df['aip-path'] = aip_path

      end

      Datyl::Logger.info "Finished creating wip from tar for #{id}"

      unless File.directory? old_xml_res_tarball_dir
        FileUtils.mkdir old_xml_res_tarball_dir
      end

      pattern = File.join tdir, aip_dir, "#{XML_RES_TARBALL_BASENAME}-*.tar"

      Dir[pattern].each do |f|
        FileUtils.cp f, File.join(old_xml_res_tarball_dir, File.basename(f))
      end

    ensure
      FileUtils.rm_r tdir
    end

    # transfer package wide events and agents
    def load_d1_package_digiprov
      es = PremisEvent.all(:relatedObjectId => self.package.uri)
      metadata['old-digiprov-events'] = es.map { |e| e.to_premis_xml.to_s }.join "\n"

      as = es.map { |e| e.premis_agent }
      metadata['old-digiprov-agents'] = as.flatten.map { |a| a.to_premis_xml.to_s }.join "\n"
    end

    # restore duplicates deleted by d1
    def restore_deleted_duplicates
      # retrieve the list of deleted duplicates if there is any
      deleted_duplicates = D1DeletedFile.all(:ieid => self.package.id)
      # restore the duplicates in the package
      deleted_duplicates.each_with_index do |dup, ix|
        source_df = original_datafiles.find { |df| df['sip-path'] == dup.source }
        dup_df = new_original_datafile ix
        FileUtils::cp source_df.data_file, dup_df.data_file
        dup_df['sip-path'] = dup.duplicate
        dup_df['aip-path'] = File.join Wip::SIP_FILES_DIR, dup.duplicate

        # add a 'redup' event for restoring d1 deleted duplicated files.
        dup_df['redup-event'] = redup_event dup_df, "restore from #{dup.source}"
        dup_df['redup-agent'] = system_agent

      end

    end

    def compile_globals
      d1adapter = DataMapper.setup(:daitss1, archive.d1_db_url)

      sql_query = %Q{
        select concat(IEID,'/',PACKAGE_PATH)
        from (select DFID
              from INT_ENTITY_GLOBAL_FILE
              where IEID='#{id}') dfs, DATA_FILE
        where DATA_FILE.DFID=dfs.DFID
          and DATA_FILE.PACKAGE_PATH not like binary '%_LOC%'
          and DATA_FILE.PACKAGE_PATH not like '%dls/md/daitss/daitss_%.xsd';
      }

      ps = d1adapter.select sql_query

      tarball_file = File.expand_path(File.join(old_xml_res_tarball_dir, "#{Wip::XML_RES_TARBALL_BASENAME}-0.tar"))

      tdir = Dir.mktmpdir

      Dir.chdir tdir do
        pdir = self.package.id
        FileUtils.mkdir pdir

        ps.each do |f|
          gf_path = File.join archive.d1_globals_dir, f
          tb_path = File.join pdir, f
          FileUtils.mkdir_p File.dirname(tb_path)
          FileUtils.ln_s gf_path, tb_path
        end

        %x{tar --dereference --create --file #{tarball_file} #{pdir}}
        raise "could not make tarball: #{$?}" unless $?.exitstatus == 0
      end

    ensure
      FileUtils.rm_r tdir if tdir and File.exist?(tdir)
    end

  end

end
