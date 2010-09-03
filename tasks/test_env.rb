require 'daitss/config'
require 'fileutils'

module TestEnv
  VAR_DIR = File.expand_path File.join(File.dirname(__FILE__), '..', 'var')
  LOG_DIR = File.join VAR_DIR, 'log'
  PID_DIR = File.join VAR_DIR, 'pids'
  WORKSPACE_DIR = File.join VAR_DIR, 'work'
  STASHSPACE_DIR = File.join VAR_DIR, 'stash'
  SERVICES_DIR = File.join VAR_DIR, 'services'
  SILO_DIR = File.join VAR_DIR, 'silo'
  DATABASE_URL = "postgres://localhost/daitss"
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
      File.join SERVICES_DIR, @name
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
      File.join PID_DIR, "#{name}.pid"
    end

    def log_file
      File.join LOG_DIR, "#{name}.log"
    end

    def ru_file

      f = abs_join File.dirname(__FILE__), "#{name}.ru"

      if File.exist? f
        f
      else
        File.join dir, 'config.ru'
      end

    end

    def start  port
      [ LOG_DIR, PID_DIR ].each { |d| FileUtils.mkdir_p d unless File.exist? d }

      Dir.chdir dir do
        command = "thin --daemonize -c #{dir} --environment development --tag #{name} --port #{port} -P #{pid_file} -l #{log_file} -R #{ru_file} start"

        unless name == 'statusecho'
          command = "bundle exec " + command
        end

        system command
        raise "cannot start #{name}" unless $?.exitstatus == 0
      end

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

  SERVICES = %w(actionplan describe statusecho storage transform viruscheck).map { |s| Service.new s }

  def config

    h = {
      'uri-prefix' => 'daitss-test',
      'http-timeout' => 600,
      'data' => DATA_DIR,
      'database-url' => DATABASE_URL,
      'jvm-options' => ["-Dhttp.proxyHost=sake.fcla.edu", "-Dhttp.proxyPort=3128", "-Xms2G", "-Xmx2G"]
    }

    SERVICES.each_with_index { |s,ix| h[s.name] = "http://localhost:#{BASE_PORT + ix}" }
    h['xmlresolution'] = 'http://xmlresolution.dev.fcla.edu'
    Daitss::CONFIG.merge! h
  end
  module_function :config

  def mkdirs
    dirs = [VAR_DIR, LOG_DIR, PID_DIR, DATA_DIR, Archive.stash_path, Archive.work_path, SERVICES_DIR, SILO_DIR]
    dirs.each { |d| FileUtils.mkdir_p d unless File.exist? d }
  end
  module_function :mkdirs

end
