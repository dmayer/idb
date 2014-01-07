require_relative 'console_widget'
require_relative 'cycript_thread'
require 'open3'


class CycriptConsoleWidget < Qt::Widget

  def initialize *args
    super *args
    @to_send = nil
    @console = ConsoleWidget.new
    @console.connect(SIGNAL('command(QString)')) {|cmd|
      puts cmd.inspect
      @cycript_thread.send_data cmd + "\n"
#      @cycript_thread.send_data "testtest\n"
    }

    @start = Qt::PushButton.new "Start"
    @start.connect(SIGNAL :released) {
#      @start.setEnabled(false)
#      @stop.setEnabled(true)
      start

      #@console.result data

    }

    @stop = Qt::PushButton.new "Stop"
    @stop.connect(SIGNAL :released) {
     Thread.list.each {|t| p t}
      @cycript_thread.send_data "testtest\n"
      Thread.pass

    }

    layout = Qt::VBoxLayout.new do |v|
      v.add_widget(@console)
      v.add_widget(@start)
      v.add_widget(@stop)
    end
    setLayout(layout)


    end
  def pure_string s
    x =  loop{ s[/\033\[\d+m/] = "" }
    rescue IndexError
        return s
    x
  end

  def start
      @cycript_thread = CycriptThread.new
      @cycript_thread.connect(SIGNAL('new_entry(QString)')) {|line|
        @console.result line
      }
    @cycript_thread.launch_process
  end

  def stop
    @cycript_thread.stop
  end




end