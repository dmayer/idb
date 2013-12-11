class CacheDbWidget < Qt::Widget

  def initialize *args
    super *args

    @refresh = Qt::PushButton.new "Refresh"
    @refresh.connect(SIGNAL :released) {
      refresh
    }

    @list = Qt::ListWidget.new self
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
      item.setText full_path.sub($selected_app.app_dir,'')
      item.full_path = full_path
      @list.addItem item
    }
  end

end