require 'uri'

require 'create'
require 'file'
require 'metadata'
require 'ingest'
require 'validate'
require 'provenance'

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
    raise "cannot locate package: #{url}" unless File.directory?(@url.path)
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
    open(File.join(files_dir, final_path), "w") { |final_io| final_io.write io.read }

    # update the descriptor
    fid = next_file_id doc
    fileGrp = doc.find_first('//mets:fileGrp', NS_MAP) << make_file_ref(final_path, fid)
    doc.find_first('/mets:structMap/mets:div', NS_MAP) << make_fptr(fid)
    doc.save descriptor_file
    
    DFile.new self, fid
  end
  
  def to_s
    url.to_s
  end
  
  # Returns the absolute path to the files directory
  def files_dir
    File.join path, 'files'
  end
  
  # Returns the absolute path to the package metadata directory
  def md_dir
    File.join path, 'aip-md'
  end

  # Returns the absolute path to the file metadata directory
  def file_md_dir
    File.join path, 'file-md'
  end

      
  def write_reject_info e
    reject_info_file = File.join(path, 'REJECT')
    
    open(reject_info_file, "w") do |io|
      io.puts Time.now

      e.reasons.each do |r|
        io.puts "%s %s: %s" % [ r[:time].strftime('%c'), r[:type], r[:message] ]
      end

    end
    
  end

  def write_snafu_info e
    
    open(File.join(path, 'SNAFU'), "w") do |io|
      io.puts Time.now
      io.puts e.message
      io.puts e.backtrace
    end
    
  end
  
  protected
  
  # Make a new path for a data file
  def new_file_path
    tf = Tempfile.new 'new-file', files_dir
    relative_path = tf.path[(path.length + 1)..-1]
    tf.close!  
    relative_path
  end
  
  # Return the next file id
  def next_file_id doc
    # TODO
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
