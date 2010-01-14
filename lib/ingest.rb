require 'aip'
require 'wip'
require 'representation'
require 'service/validate'
require 'service/describe'
require 'descriptor'
require 'template/premis'

class Wip

  def step key

    unless tags.has_key? key
      yield
      tags[key] = Time.now.xmlschema
    end

  end

  def ingest!
    
    begin
      #step('ingest') # mark the start of this ingest
      step('validate') { validate! }
      datafiles.each { |df| step("describe-#{df.id}") { df.describe! } }

      # determine existing original_rep and current_rep
      step('set-original-representation') { self.original_rep = datafiles if original_rep.empty? }
      step('set-current-representation') { self.current_rep = original_rep if current_rep.empty? }

      # new reps
      #new_current_rep = current_rep.map { |df| df.migrate || df } 
      #new_normalized_rep = original_rep.map { |df| df.normalize || df }
    
      # persist the representations
      #step('update-current-representation') { current_rep = new_current_rep unless new_current_rep.empty? }
      #step('update-normalized-representation') { normalized_rep = new_normalized_rep unless new_normalized_rep.empty? }

      # clean out undescribed files
      represented_files, unrepresented_files = represented_partitions
      unrepresented_files.each { |df| step("obsolete-#{df.id}") { df.obsolete! } }

      # TODO write ingest event
      # step('prove-ingest') { metadata[''] }
      
      # TODO import old package level provenance
      # TODO make sure obsolete datafiles have premis objects
      # TODO import old data file level provenance for each data file even obsolete ones

      step('write-ingest-event') do
        metadata['ingest-event'] = event(:id => URI.join(uri, 'event', 'ingest').to_s, 
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
    puts aip.xml
    aip.needs_work = true
    aip.url = "#{CONFIG['storage-url']}/#{id}"

    aip.tarball = Tarball.new do |t|
      t.add File.join(id, "descriptor.xml"), aip.xml

      files.each do |f| 
        tar_path = File.join id, 'files', f['sip-path']
        t.add tar_path, f.data
      end

    end

    unless aip.save 
      raise "could not save aip"
    end

  end

end
