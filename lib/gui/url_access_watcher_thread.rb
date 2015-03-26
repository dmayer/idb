module Idb
  class URLWatcherThread < Qt::Object
    signals "new_entry(QString)"

    def initialize *args
      super *args
      $terminate_urlwatcher_thread = false
    end

    def stop
      $terminate_urlwatcher_thread = true
      @ssh.close
    end


    def start_urlwatcher_thread
      hostname = $settings.ssh_host
      username = $settings.ssh_username
      password = $settings.ssh_password
      port = $settings.ssh_port


      @urlwatcher_thread = Thread.new do

        begin
          if $settings['device_connection_mode'] == "ssh"
            $log.info "Establishing SSH Session for #{username}@#{hostname}:#{port}"
            @ssh = Net::SSH.start hostname, username, :password => password, :port => port
          else
            $log.info "Establishing SSH-via-USB Session using existing proxy and #{username}@localhost:#{$device.proxy_port}"
            @ssh = Net::SSH.start "localhost", username, :password => password, :port => $device.proxy_port
          end

        rescue Exception => ex
          $log.error ex.message
          error = Qt::MessageBox.new
          error.setInformativeText("SSH connection for URL scheme watching could not be established: #{ex.message}. In order to use this feature, idb has to be able to establish multiple SSH connections to the device. If SSH vis USB (usbmuxd) is used, please make sure it is at least version 1.0.10 which supports this.")
          error.setIcon(Qt::MessageBox::Critical)
          error.exec
        end
        channel = @ssh.open_channel do |ch|
          ch.request_pty do |ch, success|
          cmd = "/usr/bin/tail -f /var/root/url_handler.log"
          $log.info "Tailing /var/root/call.log : #{cmd}"
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
               $log.info "urlwatcher terminated"
             }
          end
            end
        end

        @ssh.loop


#        loop do
#          @ssh.process
#          if $terminate_urlwatcher_thread
#            $log.info "Terminating urlwatcher"
#            channel.close
#            break
#          end
#        end
#        $log.info "Terminating thread"
      end


    end


  end
end
