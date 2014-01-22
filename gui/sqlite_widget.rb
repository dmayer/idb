require_relative '../lib/console_launcher'

class SqliteWidget  < Qt::Widget

  def initialize *args
    super *args

    @refresh = Qt::PushButton.new "Refresh"
    @refresh.connect(SIGNAL :released) {
      refresh
    }

    @list = Qt::ListWidget.new self
    @list.connect(SIGNAL('itemDoubleClicked(QListWidgetItem*)')) { |item|
      if RbConfig::CONFIG['host_os'] =~ /linux/
        Process.spawn "'#{$settings['sqlite_editor']}' '#{Dir.getwd}/#{$selected_app.cache_file item.full_path}'"
      else
        Process.spawn "open -a '#{$settings['sqlite_editor']}' '#{Dir.getwd}/#{$selected_app.cache_file item.full_path}'"
      end

      x = ConsoleLauncher.new
      #TODO: find sqlite binary
      #http://www.ruby-doc.org/stdlib-2.0.0/libdoc/mkmf/rdoc/MakeMakefile.html#method-i-find_executable
      #x.run "/usr/bin/sqlite3 #{Dir.getwd}/#{$selected_app.cache_file item.full_path}"



    }
   # "Launch app"

    layout = Qt::VBoxLayout.new do |v|
      v.add_widget(@list)
      v.add_widget(@refresh)
    end
    setLayout(layout)
  end

  def clear
    @list.clear
  end


  def refresh
    @list.clear
    sqlite_dbs = $selected_app.find_sqlite_dbs
    sqlite_dbs.each { |full_path|
      item = PathListWidgetItem.new
      pc = $device.protection_class full_path
      item.setText full_path.sub($selected_app.app_dir,'') + " => " + pc.strip
      item.full_path = full_path
      @list.addItem item
    }
  end
end