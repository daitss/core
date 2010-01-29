require 'tempdir'
require 'db/aip'
require 'wip'
require 'wip/step'
require 'representation'
require 'service/validate'
require 'service/describe'
require 'service/actionplan'
require 'service/transform'
require 'descriptor'
require 'template/premis'

class Wip

  def ingest!
    
    begin
      step('validate') { validate! }

      preserve!



      # TODO import old package level provenance
      # TODO make sure obsolete datafiles have premis objects
      # TODO import old data file level provenance for each data file even obsolete ones

      # write the ingest event
      step('write-ingest-event') do
        metadata['ingest-event'] = event(:id => "#{uri}/event/ingest", 
                                         :type => 'ingest', 
                                         :outcome => 'success', 
                                         :linking_objects => [ uri ])
      end

      make_aip! represented_files
    rescue Reject => e
      tags['REJECT'] = e.message
    rescue => e
      tags['SNAFU'] = ( [e.message] + e.backtrace ).join "\n"
    end

  end

  private

  def make_aip! files

    aip = Aip.new
    aip.id = id
    aip.uri = uri
    aip.xml = descriptor.to_s
    aip.needs_work = true
    aip.copy_url = "#{CONFIG['storage-url']}/#{id}"

    Tempdir.new do |dir|

      Dir::chdir(dir.path) do

        #make the stuff
        FileUtils::mkdir aip.id

        files.each do |f|
          sip_path = File.join aip.id, f['sip-path']
          FileUtils::mkdir_p File.dirname(sip_path)
          FileUtils::ln_s f.datapath, sip_path
        end

        descriptor_path = File.join(aip.id, 'descriptor.xml')
        open(descriptor_path, 'w') { |io| io.write aip.xml }

        #tar it up
        aip.tarball = %x{tar --dereference --create --file -  #{aip.id}}
        raise "could not make tarball: #{$?}" unless $?.exitstatus == 0
      end

    end

    unless aip.save 
      aip.errors.each { |e| puts e }
      raise "could not save aip: #{aip.errors.size}"
    end

  end

end
