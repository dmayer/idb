require_relative '../lib/tools'

module Idb
  class IDeviceSyslogThread <  Qt::Object
    signals "new_entry(QString)"

    def initialize *args
      super *args
      $terminate_syslog_thread = false
      if which('idevicesyslog').nil?
        error = Qt::MessageBox.new
        error.setInformativeText("This feature requires  idevicesyslog to be installed on the host running idb. Try:<br>OS X: brew install libimobiledevice<br>Ubuntu: apt-get install libimobiledevice-utils")
        error.setIcon(Qt::MessageBox::Critical)
        error.exec
        return false
      end
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
end