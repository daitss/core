require 'forwardable'
require 'fileutils'

require 'mixin/file'

require 'proc/fshash'
require 'proc/fileattr'
require 'proc/statevar'
require 'proc/wip/journal'
require 'proc/wip/process'

require 'proc/wip/ingest'
require 'proc/wip/disseminate'
require 'proc/wip/d1_refresh'

require 'proc/wip/queue_report.rb'
require 'proc/template'

class Wip
  include DataDir
  extend DataDir

  def self.all
    pattern = File.join work_path, '*'
    Dir[pattern].map { |p| Wip.new p }
  end

  def self.get id
    w_path = File.join work_path, id
    s_path = File.join stash_path, id

    if File.exist? w_path
      Wip.new w_path
    elsif File.exist? s_path
      Wip.new s_path
    end
  end

  extend Forwardable
  extend StateVar
  extend FileAttr

  METADATA_DIR = 'metadata'
  FILES_DIR = 'files'
  ORIGINAL_FILES = File.join FILES_DIR, 'original'
  NORMALIZED_FILES = File.join FILES_DIR, 'normalized'
  MIGRATED_FILES = File.join FILES_DIR, 'migrated'
  OLD_XML_RES_DIR = 'xmlresolutions'

  attr_reader :id, :path, :metadata
  attr_reader :id, :path, :metadata

  def_delegators :@metadata, :[]=, :[], :has_key?, :delete

  state_var :info, :default => {}
  state_var :journal, :default => {}
  state_var :process

  file_attr :tarball
  file_attr :xmlres

  md_file_attr :aip_descriptor
  md_file_attr :aip_descriptor_errata

  VALID_TASKS = [
    :sleep,
    :ingest,
    :disseminate,
    :withdraw,
    :peek,
    :d1refresh
  ]

  DMD_KEYS = ['dmd-issue', 'dmd-volume', 'dmd-title', 'dmd-entity-id']

  SIP_FILES_DIR = 'sip-files'

  # make a new wip on the filesystem
  def self.create path, task

    unless VALID_TASKS.include? task
      raise "Unknown task: #{task}"
    end

    FileUtils.mkdir path

    Dir.chdir path do

      [ METADATA_DIR,
        FILES_DIR,
        ORIGINAL_FILES,
        NORMALIZED_FILES,
        MIGRATED_FILES,
        OLD_XML_RES_DIR
      ].each do |f|
        FileUtils.mkdir f
      end

    end

    w = Wip.new path
    w.info[:task] = task
    w.save_info
    w
  end

  def self.create_from_request req
    p = req.package
    s = req.submission
    w = Wip.create File.join(DataDir.work_path, p.id), req.type

    s.files.each_with_index do |f, n|
      df = w.new_original_datafile n
      FileUtils.cp File.join(s.path, f), df.data_file
      df['sip-path'] = f
      df['aip-path'] = File.join SIP_FILES_DIR, f
    end

    w['sip-descriptor'] = File.read s.descriptor_file

    w
  end

  # initialize a wip object from a filesystem wip
  def initialize path
    @path = File.expand_path path
    @id = File.basename @path
    @metadata_path = File.join @path, METADATA_DIR

    @metadata = FsHash.new File.join(@path, METADATA_DIR)
    @cached_max_id = {}

    File.lock @path, :shared => true do
      load_info
      load_journal
      load_process
    end

  end

  alias_method(:to_s, :id)

  def == other
    id == other.id and path == other.path
  end
  alias_method(:eql?, :==)

  def task
    @info[:task]
  end

  # @return [Array] the original datafiles
  def original_datafiles
    datafiles ORIGINAL_FILES
  end

  # add a new original datafile
  #
  # @param [String] id of the new datafile
  def new_original_datafile id
    new_datafile ORIGINAL_FILES, id
  end

  # @return [Array] the migrated datafiles
  def migrated_datafiles
    datafiles MIGRATED_FILES
  end

  # add a new migrated datafile
  #
  # @param [String] id of the new datafile
  def new_migrated_datafile id
    new_datafile MIGRATED_FILES, id
  end

  # @return [Array] the normalized datafiles
  def normalized_datafiles
    datafiles NORMALIZED_FILES
  end

  # add a new normalized datafile
  #
  # @param [String] id of the new datafile
  def new_normalized_datafile id
    new_datafile NORMALIZED_FILES, id
  end

  # @return [Array] all datafiles
  def all_datafiles
    original_datafiles + normalized_datafiles + migrated_datafiles
  end

  # @return [Package] the package this wip is operating on
  def package
    @package ||= Package.get id
  end

  # @return [StashBin] the stashbin containing this wip if stashed
  def bin
    dir = File.dirname path
    bins = archive.stashspace
    bins.find { |b| b.path == dir }
  end

  # @return [Boolean] true if it is stashed
  def stashed?
    not bin.nil?
  end

  # @return [String] the direcetory containing any old xml resolution tarballs
  def old_xml_res_tarball_dir
    File.join @path, OLD_XML_RES_DIR
  end

  # @return [Array] any old xml resolution tarballs
  def old_xml_res_tarballs
    pattern = File.join old_xml_res_tarball_dir, '*'
    Dir[pattern]
  end

  def has_dmd?

    DMD_KEYS.any? do |dmd_key|
      metadata.keys.include? dmd_key
    end

  end

  def dmd
    template_by_name('aip/dmd').result binding
  end

  private

  def datafiles container
    pattern = File.join @path, container, '*'

    Dir[pattern].map do |path|
      df_id = File.basename path
      DataFile.new self, container, df_id
    end
  end

  def new_datafile container, id

    if File.exist? File.join(@path, container, id.to_s)
      raise "datafile #{id} already exists in #{container}"
    end

    DataFile.make self, container, id.to_s
  end

end

