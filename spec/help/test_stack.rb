module TestStack

  def start_sinatra
    @sinatra_port = 7000
    sinatra_dir = File.join File.dirname(__FILE__), '..', '..'
    @sinatra_pid = fork do
      Dir.chdir sinatra_dir do
        exec "./ts-sinatra", @sinatra_port.to_s
      end
    end

    wait_for_service("0.0.0.0", @sinatra_port)
  end

  def start_storage
    @storage_port = 7001
    @silo_sandbox = new_sandbox
    FileUtils::mkdir @silo_sandbox
    storage_dir = File.join(VENDOR_DIR, 'storage')
    @storage_pid = fork do
      Dir.chdir storage_dir do
        exec "ruby -Ilib bin/disk-server --network-port #{@storage_port} --silo one:#{@silo_sandbox}"
      end
    end

    wait_for_service "0.0.0.0", @storage_port
  end

  def stop_sinatra
    Process.kill 'INT', @sinatra_pid
    Process.wait @sinatra_pid
  end

  def stop_storage
    Process.kill 'INT', @storage_pid
    Process.wait @storage_pid
  end

  def nuke_silo_sandbox
    FileUtils::chmod_R 0777, @silo_sandbox # XXX strange silo perms bullshit going on here
    FileUtils::rm_rf @silo_sandbox
    FileUtils::mkdir @silo_sandbox
  end

  private

  def listening?(host, port)
    begin
      socket = TCPSocket.new(host, port)
      socket.close unless socket.nil?
      true
    rescue Errno::ECONNREFUSED,
      Errno::EBADF,           # Windows
      Errno::EADDRNOTAVAIL    # Windows
      false
    end
  end

  def wait_for_service(host, port, timeout = 5)
    start_time = Time.now

    until listening?(host, port)
      if timeout && (Time.now > (start_time + timeout))
        raise SocketError.new("Socket did not open within #{timeout} seconds")
      end
    end

    true
  end

end
