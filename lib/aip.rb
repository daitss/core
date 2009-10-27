require 'uri'
require 'tempfile'

require 'layout'
require 'create'
require 'file'
require 'metadata'
require 'monodescriptor'
require 'ingest'
require 'service/validate'
require 'service/provenance'
require 'service/store'
require 'next'

# File System based AIP
class Aip

  attr_reader :url

  include Metadata
  include Monodescriptor
  include Ingest
  include Validate
  include Service::Provenance
  include Store
  include Layout
  
  # Returns a new AIP based at the url, only file urls are supported.
  def initialize url
    @url = URI.parse url
    @url.scheme = 'file' unless @url.scheme
    raise "unsupported url: #{@url}" unless @url.scheme == 'file'
    raise "cannot locate package: #{@url}" unless File.directory?(@url.path)
  end
  
  # Returns the path to the aip on the file system
  def path
    @url.path
  end
  alias_method :package_dir, :path

  # The interim descriptor that is built
  def poly_descriptor_file
    File.join path, POLY_DESCRIPTOR_FILE
  end
  
  # An xml document of the poly-descriptor
  def poly_descriptor_doc
    open(poly_descriptor_file) { |io| XML::Parser.io(io).parse }
  end
  
  # Returns an array of DFile objects
  def files
    
    poly_descriptor_doc.find('//mets:file', NS_MAP).map do |file_node|
      DFile.new self, file_node['ID']
    end
    
  end

  # Creates a new file with the data read from io
  def add_file io, fpath=nil, owner_id=nil
    
    modify_poly_descriptor do |doc|

      # write the data
      final_path = if fpath
        raise 'file paths must be relative' if fpath =~ %r{^/}
        fpath
      else
        new_file_path
      end

      abs_path = File.join files_dir, final_path
      FileUtils::mkdir_p File.dirname(abs_path)
      open(abs_path, "w") { |final_io| final_io.write io.read }

      # update the descriptor
      file_ids = doc.find("//mets:file/@ID", NS_MAP).map { |a| a.value.strip }
      next_file_id = next_in_set(file_ids, /file-(\d+)/)
      fid = "file-#{next_file_id}"
      fileGrp = doc.find_first('//mets:fileGrp', NS_MAP) << make_file_ref(abs_path[(path.length + 1)..-1], fid, owner_id)
      doc.find_first('//mets:structMap/mets:div', NS_MAP) << make_fptr(fid)
      
      # a file to return
      dfile = DFile.new self, fid

      # make the meta data dir for this file
      FileUtils::mkdir dfile.md_dir

      dfile
    end
    
  end
  
  def to_s
    url.to_s
  end
  
  # Returns the absolute path to the files directory
  def files_dir
    File.join path, FILES_DIR
  end
  
  # Returns the absolute path to the package metadata directory
  def md_dir
    File.join path, AIP_MD_DIR
  end

  # Returns the absolute path to the file metadata directory
  def file_md_dir
    File.join path, FILE_MD_DIR
  end
      
  # Returns the path to the reject tag file
  def reject_tag_file
    File.join path, 'REJECT'
  end
  
  # Returns true if this package is rejected
  def rejected?
    File.exist? reject_tag_file
  end

  # Writes the set of errors to the reject tag file
  def write_reject_info e
    
    open(reject_tag_file, "w") do |io|
      io.puts Time.now

      e.reasons.each do |r|
        io.puts "#{ r[:time].strftime('%c') } #{ r[:type] }: #{ r[:message] }"
      end

    end
    
  end

  # Returns a path to the snafu tag file
  def snafu_tag_file
    File.join path, 'SNAFU'
  end
  
  # Returns true if the aip is snafu
  def snafu?
    File.exist? snafu_tag_file
  end

  # Writes the error to the snafu tag file
  def write_snafu_info e
    
    open(snafu_tag_file, "w") do |io|
      io.puts Time.now
      io.puts e.message
      io.puts e.backtrace
    end
    
  end  

  # Removes the aip from the file system
  def cleanup!
    FileUtils::rm_r path
  end
  
  # yields a xml document read from the poly descriptor and saves it when done
  # TODO flock this?
  def modify_poly_descriptor
    doc = poly_descriptor_doc
    rval = yield doc
    doc.save poly_descriptor_file
    rval
  end
    
  def represented?    
    md_for(:techmd).any? do |doc|
      xpath = "//mets:techMD/mets:mdRef[@LABEL='R0']"
      doc.find_first(xpath, NS_MAP)
    end  
  end
  
  def represent!
    # make r0
    s = template_by_name('rep_0').result binding
    doc = XML::Parser.string(s).parse
    r0_id = add_representation_md 'r0', doc
    
    # make r0
    s = template_by_name('rep_c').result binding
    doc = XML::Parser.string(s).parse
    rC_id = add_representation_md 'rC', doc
    
    # link both of these from the structmap's div
    add_div_link r0_id
    add_div_link rC_id    
  end
  
  def add_div_link md_id
    
    modify_poly_descriptor do |des_doc|
      div = des_doc.find_first "//mets:structMap/mets:div", NS_MAP
      admids = div['ADMID'] ? div['ADMID'].split(%r{\s+}) : []
      admids << md_id
      div['ADMID'] = admids.join ' '
    end
    
  end
  
  # Returns all the files that are not transformed
  def rep_0_files
    files.reject { |f| f.md_for_event?('Normalization') || f.md_for_event?('Migration') }
  end

  # Returns all the files but with transformantions substituted
  def rep_c_files
    file_digiprov_docs = files.map { |f| f.md_for :digiprov }.flatten
    transformation_events = file_digiprov_docs.map { |e| e.find_first("//premis:event[premis:eventType = 'Normalization' or premis:eventType = 'Migration']//premis:linkingObjectIdentifierValue", NS_MAP) }.compact
    fids = transformation_events.compact.map { |e| e.content.strip }
    files.reject { |f| fids.member? f.fid }
  end
  
  protected
    
  # Make a new path for a data file
  def new_file_path
    tf = Tempfile.new 'new-file', files_dir
    relative_path = tf.path[(files_dir.length + 1)..-1]
    tf.close!  
    relative_path
  end
  
  # Make a new METS file element
  def make_file_ref path, fid, owner_id
    node = XML::Node.new 'file'
    node['ID'] = fid
    node['OWNERID'] = owner_id if owner_id
    fLocat = XML::Node.new 'FLocat'
    fLocat['LOCTYPE'] = 'URL'
    fLocat['xlink:href'] = path
    node << fLocat
    node
  end
    
  # Make a new METS file pointer element
  def make_fptr(fid)
    node = XML::Node.new 'fptr'
    node['FILEID'] = fid
    node
  end
  
end
