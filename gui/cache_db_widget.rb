class CacheDbWidget < Qt::Widget

  def initialize *args
    super *args

    @refresh = Qt::PushButton.new "Refresh"
    @refresh.connect(SIGNAL :released) {
      refresh
    }

    @list = Qt::ListWidget.new self
    @list.connect(SIGNAL('itemDoubleClicked(QListWidgetItem*)')) { |item|
#      x = ConsoleLauncher.new
      #TODO: find sqlite binary
      #x.run "/usr/bin/sqlite3 #{Dir.getwd}/#{$selected_app.cache_file item.full_path}"
        Process.spawn "open -a '#{$settings['sqlite_editor']}' '#{Dir.getwd}/#{$selected_app.cache_file item.full_path}'"
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
    cache_dbs = $selected_app.find_cache_dbs
    cache_dbs.each { |full_path|
      item = PathListWidgetItem.new
      pc = $device.protection_class full_path
      item.setText full_path.sub($selected_app.app_dir,'') + " => " + pc.strip
      item.full_path = full_path
      @list.addItem item
    }
  end

end