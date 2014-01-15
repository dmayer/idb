require_relative 'pb_watcher_thread'
require_relative 'log_plain_text_edit'

class PasteboardMonitorWidget < Qt::Widget

  def initialize *args
    super *args

    @pbs_to_watch = Hash.new
    @pbs_to_watch["general"] = ""


    @stop = Qt::PushButton.new "Stop"
    @stop.setEnabled(false)
    @stop.connect(SIGNAL :released) {
      @start.setEnabled(true)
      @stop.setEnabled(false)
      stop_log
      @pb_config.setEnabled(true)
    }

    @log_window = LogPlainTextEdit.new
    @log_window.setReadOnly(true)

    @start = Qt::PushButton.new "Start"
    @start.connect(SIGNAL :released) {
      unless $device.pbwatcher_installed?
        error = Qt::MessageBox.new
        error.setInformativeText("pbwatcher not found on the device. Please visit the status dialog and install it.")
        error.setIcon(Qt::MessageBox::Critical)
        error.exec
      else
        @pb_config.setEnabled(false)
        @start.setEnabled(false)
        @stop.setEnabled(true)
        launch_process
      end
    }


    @pb_config = Qt::GroupBox.new self
    @pb_config.setTitle "Pasteboard Names"
    @pb_config_layout = Qt::GridLayout.new
    @pb_config.setLayout @pb_config_layout

    @pb_names = Qt::ListWidget.new @self

    @pb_add = Qt::PushButton.new "Add"
    @pb_add.connect(SIGNAL :released) {
      @pbs_to_watch[@pb_text.text] = ""
      @pb_names.addItem @pb_text.text
      @pb_text.text = ""
      @pb_remove.setEnabled(true)
    }


    @pb_remove = Qt::PushButton.new "Remove"
    @pb_remove.setEnabled(false)
    @pb_remove.connect(SIGNAL :released) {
      removed_pb = @pb_names.item(@pb_names.current_row)
      @pbs_to_watch.delete removed_pb.text unless removed_pb.nil?

      row = @pb_names.current_row
      @pb_names.takeItem  row unless row.nil?
      if @pb_names.count == 0
        @pb_remove.setEnabled(false)
      end
    }

    @pb_text = Qt::LineEdit.new

    @pb_config_layout.addWidget @pb_names, 0, 0, 1, 2
    @pb_config_layout.addWidget @pb_text, 1, 0, 1, 2
    @pb_config_layout.addWidget @pb_add, 2, 0, 1, 1
    @pb_config_layout.addWidget @pb_remove, 2, 1, 1, 1


    layout = Qt::GridLayout.new do |h|
      h.add_widget @log_window, 0,0
      h.add_widget @pb_config, 0,1

      h.add_widget @start, 1, 0, 1, 2
      h.add_widget @stop, 2, 0, 1, 2
    end
    setLayout(layout)

  end


  def launch_process
    h = HTMLEntities.new
    @log_window.append_message "Please wait.."
    @pbwatcher_thread = PBWatcherThread.new
    @pbwatcher_thread.connect(SIGNAL('new_entry(QString)')) {|line|
      color = 'black'
      date, time, app, payload = line.split " ", 4
      pb, data = payload.split ":", 2
      if @pbs_to_watch[pb] != data
        @pbs_to_watch[pb] = data
        new_entry = "#{time} #{pb} => #{data}"
        new_entry = new_entry.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_')
        @log_window.append_message "<font color='#{color}'>#{h.encode(new_entry.chomp)}</font>"
      end


    }
    @pbwatcher_thread.start_pbwatcher_thread @pbs_to_watch.select{|x,y| x != 'general' }.map{|x,y| "\"#{x}\""}.join ' '

  end

  def stop_log
    @pbwatcher_thread.stop
  end
end