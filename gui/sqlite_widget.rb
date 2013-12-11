class SqliteWidget  < Qt::Widget

  def initialize *args
    super *args

    @refresh = Qt::PushButton.new "Refresh"
    @refresh.connect(SIGNAL :released) {
      refresh
    }

    @list = Qt::ListWidget.new self
    @list.connect(SIGNAL('itemDoubleClicked(QListWidgetItem*)')) { |item|
      $device.ops.open $selected_app.cache_file item.full_path
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
      item.setText full_path.sub($selected_app.app_dir,'')
      item.full_path = full_path
      @list.addItem item
    }
  end
end