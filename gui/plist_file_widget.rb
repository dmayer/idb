require_relative 'path_list_widget_item'

class PlistFileWidget < Qt::Widget

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
    @list.setContextMenuPolicy(Qt::CustomContextMenu);
    @list.connect(SIGNAL('customContextMenuRequested(QPoint)')) { |item|
      menu = Qt::Menu.new("Context menu", self)
      menu.addAction(Qt::Action.new("Hello", self));
      menu.exec(mapToGlobal(pos));

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
    plist_files = $selected_app.find_plist_files
    plist_files.each { |full_path|
      item = PathListWidgetItem.new
      item.setText full_path.sub($selected_app.app_dir,'')
      item.full_path = full_path
      @list.addItem item
    }
  end




end