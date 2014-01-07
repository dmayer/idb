class PBWatcherThread < Qt::Object
  signals "new_entry(QString)"

  def initialize *args
    super *args
    $terminate_pbwatcher_thread = false
  end


  def stop
    $terminate_pbwatcher_thread = true
  end


  def start_pbwatcher_thread pbs
    @pbwatcher_thread = Thread.new do
      channel = $device.ssh.open_channel do |ch|
        ch.request_pty do |ch, success|
        cmd = "/var/root/pbwatcher 1 #{pbs}"
        $log.info "Executing pbwatcher: #{cmd}"
        ch.exec cmd do |ch, success|
          $log.error "could not execute command" unless success

          # "on_data" is called when the process writes something to stdout
          ch.on_data do |c, data|
            emit new_entry(data)
          end

           # "on_extended_data" is called when the process writes something to stderr
           ch.on_extended_data do |c, type, data|
             emit new_entry(data)
           end

           ch.on_close { |ch|
             $log.info "pbwatcher terminated"
           }
        end
          end
      end

      loop do
        #TODO mutex to protect device?
        #even better: make one central thread that calls process.
        # and all functions using it call it to ensure its running. or auto start it.
        sleep 0.5
        $device.ssh.process
        #$device.ssh.process 0
        if $terminate_pbwatcher_thread
          $log.info "Terminating pbwatcher"
          channel.close
          break
        end
      end
      $log.info "Terminating thread"
    end


  end


end
