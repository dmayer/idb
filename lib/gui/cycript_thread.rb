require 'net/ssh'

module Idb
  class CycriptThread < Qt::Object
    signals "new_entry(QString)"

    attr_accessor :channel

    def initialize *args
      super *args
      $terminate_cycript_thread = false
      @queue = Queue.new



    end

    def send_data data
      puts "sending data"
    #  @queue << data
      @channel.send_data data
  #      @channel.send_data "testtest\n"
    end


    def stop
      $terminate_cycript_thread = true
    end

    def launch_process

         @channel = $device.ssh.open_channel do |ch|
          channel.request_pty do |ch, success|
            raise "Error requesting pty" unless success
            ch.exec("export TERM=vt220; stty -echo -icanon; cycript -p SpringBoard") do |ch, success|
              raise "Error opening shell" unless success

              ch.on_extended_data do |ch, type, data|
                STDOUT.print "Error: #{data}\n"
              end

              ch.on_data do |ch, data|
                puts "emitting"
                emit new_entry(data)
                puts "done"
              end

              ch.on_close { |ch|
                $log.info "cycript terminated"
              }


            end
          end
         end


          puts "thred"
        @abc = Thread.new do
        loop do
          #TODO mutex to protect device?
          #even better: make one central thread that calls process.
          # and all functions using it call it to ensure its running. or auto start it.
          sleep 0.5
          puts "loop"
          $device.ssh.loop 0.1
          puts "done"
          if $terminate_cycript_thread
            $log.info "Terminating cycript"
            channel.close
            break
          end
        end
        $log.info "Terminating thread"
      end


    end

  end
end