require_relative 'console_widget'
require 'open3'


class CycriptConsoleWidget < Qt::Widget

  def initialize *args
    super *args
    @to_send = nil
    @console = ConsoleWidget.new
    @console.connect(SIGNAL('command(QString)')) {|cmd|
      puts cmd.inspect
      $channel.send_data cmd + "\n"
    }

    @start = Qt::PushButton.new "Start"
    @start.connect(SIGNAL :released) {
#      @start.setEnabled(false)
#      @stop.setEnabled(true)
      launch_process
    }

    layout = Qt::VBoxLayout.new do |v|
      v.add_widget(@console)
      v.add_widget(@start)
    end
    setLayout(layout)


  end


  def launch_process


    #@input, @output, @error = Open3::popen3 "bash"
    #  @io = IO.popen "bash", "w"
    Thread.new do
      puts "launching"
      @cycript = $device.ssh.open_channel
      sleep 5
      puts "hopefully open"
      puts @cycript
      #@cycript.request_pty

#       channel.exec "passwd" do |ch, success|
      @cycript.exec "ls" do |ch, success|
#         channel.exec 'ls' do |ch, success|
        if success
          puts "setting up callbacks"
          ch.on_data do |ch2, data|
            puts "got data"
            puts data
            @console.result data
          end

          @cycript.on_data do |ch2, data|
            puts "got data"
            puts data
            @console.result data
          end

          ch.on_extended_data do |ch, type, data|
            puts "got stderr: #{data}"
            @console.result data
          end
        else
          puts "FAILED"
        end

      end
#
      loop do
        #TODO mutex to protect device?
        sleep 0.5
        $device.ssh.process
        #$device.ssh.process 0
      end

#      $device.ssh.loop
      puts "done"
    end

  end


end