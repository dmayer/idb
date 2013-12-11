class IDeviceSyslogThread <  Qt::Object
  signals "new_entry(QString)"

  def initialize *args
    super *args
    $terminate_syslog_thread = false
    start_log_thread
    puts @log_thread
  end


  def stop
    $terminate_syslog_thread = true
  end


private
  def start_log_thread
    @log_thread = Thread.new do
      @log = IO.popen("idevicesyslog")
      @log.each do |line|
        if $terminate_syslog_thread
          break
        end
        emit new_entry(line)
      end
      puts "[*] Terminating thread"
      Process.kill("INT", @log.pid)
      @log.close
    end


  end


end