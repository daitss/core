require 'uri'
require 'tempfile'

require 'layout'
require 'create'
require 'file'
require 'metadata'
require 'ingest'
require 'packagelevel/validate'
require 'packagelevel/provenance'
require 'next'

# File System based AIP
class Aip

  attr_reader :url

  include Metadata
  include Ingest
  include Validate
  include Provenance
  
  def initialize url
    @url = URI.parse url
    raise "unsupported url: #{@url}" unless @url.scheme == 'file'
    raise "cannot locate package: #{@url}" unless File.directory?(@url.path)
  end
  
  def path
    @url.path
  end
  
  alias_method :package_dir, :path
    
  def descriptor_file
    File.join path, 'descriptor.xml'
  end
  
  def files
    doc = XML::Parser.file(descriptor_file).parse
    
    doc.find('//mets:file', NS_MAP).map do |file_node|
      DFile.new self, file_node['ID']
    end
    
  end

  # Creates a new file with the data read from io
  def add_file io, fpath=nil
    doc = XML::Parser.file(descriptor_file).parse
        
    # write the data
    final_path = if fpath
      raise 'file paths must be relative' if fpath =~ %r{/}
      fpath
    else
      new_file_path
    end

    abs_path = File.join files_dir, final_path
    open(abs_path, "w") { |final_io| final_io.write io.read }

    # update the descriptor
    file_ids = doc.find("//mets:file/@ID", NS_MAP).map { |a| a.value.strip }
    next_file_id = next_in_set(file_ids, /file-(\d+)/)
    fid = "file-#{next_file_id}"
    fileGrp = doc.find_first('//mets:fileGrp', NS_MAP) << make_file_ref(abs_path[(path.length + 1)..-1], fid)
    doc.find_first('//mets:structMap/mets:div', NS_MAP) << make_fptr(fid)
    doc.save descriptor_file

    # a file to return
    dfile = DFile.new self, fid
    
    # make the meta data dir for this file
    FileUtils::mkdir dfile.md_dir
    
    dfile
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
      
  def reject_tag_file
    File.join path, 'REJECT'
  end
  
  def rejected?
    File.exist? reject_tag_file
  end

  def write_reject_info e
    
    open(reject_tag_file, "w") do |io|
      io.puts Time.now

      e.reasons.each do |r|
        io.puts "%s %s: %s" % [ r[:time].strftime('%c'), r[:type], r[:message] ]
      end

    end
    
  end

  def snafu_tag_file
    File.join path, 'SNAFU'
  end
  
  def snafu?
    File.exist? snafu_tag_file
  end

  def write_snafu_info e
    
    open(snafu_tag_file, "w") do |io|
      io.puts Time.now
      io.puts e.message
      io.puts e.backtrace
    end
    
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
  def make_file_ref path, fid
    node = XML::Node.new 'file'
    node['ID'] = fid
    fLocat = XML::Node.new 'FLocat'
    fLocat['LOCTYPE'] = 'URI'
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
