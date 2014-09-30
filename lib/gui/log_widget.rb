require_relative 'log_plain_text_edit'
require_relative 'i_device_syslog_thread'
require 'htmlentities'

module Idb
  class LogWidget < Qt::Widget

  def initialize *args
    super *args

    @start = Qt::PushButton.new "Start"
    @start.connect(SIGNAL :released) {
      @start.setEnabled(false)
      @stop.setEnabled(true)
      start_log
    }

    @stop = Qt::PushButton.new "Stop"
    @stop.setEnabled(false)
    @stop.connect(SIGNAL :released) {
      @start.setEnabled(true)
      @stop.setEnabled(false)
      stop_log
    }

    @log_window = LogPlainTextEdit.new
    @log_window.setReadOnly(true)

    layout = Qt::VBoxLayout.new do |v|
      v.add_widget(@log_window)
      v.add_widget(@start)
      v.add_widget(@stop)
    end
    setLayout(layout)
    @colored = true

  end


  def start_log
    h = HTMLEntities.new
    @log_window.append_message "Please wait.. Streaming device syslog..."
    @log_thread = IDeviceSyslogThread.new
    @log_thread.connect(SIGNAL('new_entry(QString)')) {|line|
      color = 'black'
      if @colored
        if line.include? "<Notice>"
          color = 'grey'
        elsif line.include? "<Error>"
          color = 'red'
        elsif line.include? "<Warning>"
          color = 'Orange'
        elsif line.include? "<Debug>"
          color = 'Green'
        end
      end



      line = line.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_')

      @log_window.append_message "<font color='#{color}'>#{h.encode(line.chomp)}</font>"
    }
  end

  def stop_log
    @log_thread.stop
  end

  end
end