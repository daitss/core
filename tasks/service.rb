require 'fileutils'

VAR_DIR = File.join File.dirname(__FILE__), '..', 'var'
LOG_DIR = File.join VAR_DIR, 'log'
PID_DIR = File.join VAR_DIR, 'pids'
SERVICES_DIR = File.join VAR_DIR, 'services'
SILO_DIR = File.join VAR_DIR, 'silo'
BASE_PORT = 7000

class Service
  attr_reader :name

  def initialize name
    @name = name
  end

  def git_url
    "git://github.com/daitss/#{name}.git"
  end

  def checked_out?
    File.exist? dir
  end

  def dir
    abs_join SERVICES_DIR, @name
  end

  def clone fake=false

    unless fake
      Dir.chdir(SERVICES_DIR) { %x{git clone #{git_url}} }
      raise "error fetching #{name}" unless $? == 0
    else
      FileUtils.mkdir_p dir unless File.exist? dir
    end

  end

  def fetch fake=false
    FileUtils.mkdir_p dir unless File.exist? dir

    unless fake
      Dir.chdir(dir) { %x{git pull} }
      raise "error updating #{name}" unless $? == 0
    end

  end

  def bundle
    Dir.chdir(dir) { %x{bundle install} }
  end

  def pid_file
    abs_join PID_DIR, "#{name}.pid"
  end

  def log_file
    abs_join LOG_DIR, "#{name}.log"
  end

  def ru_file

    f = abs_join File.dirname(__FILE__), "#{name}.ru"

    if File.exist? f
      f
    else
      abs_join dir, 'config.ru'
    end

  end

  def start  port
    [ LOG_DIR, PID_DIR ].each { |d| FileUtils.mkdir_p d unless File.exist? d }
    system "thin --daemonize -c #{dir} --environment test --tag #{name} --port #{port} -P #{pid_file} -l #{log_file} -R #{ru_file} start"
    raise "cannot start #{name}" unless $?.exitstatus == 0
  end

  def stop
    system "thin -P #{pid_file} stop"
    raise "cannot stop #{name}" unless $?.exitstatus == 0
  end

  def running?
    File.exist? pid_file
  end

  private

  def abs_join *names
    File.expand_path(File.join *names)
  end

end
