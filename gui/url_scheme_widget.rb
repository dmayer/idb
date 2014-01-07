class URLSchemeWidget < Qt::Widget
  def initialize *args
    super *args

    @url_handler_list = Qt::GroupBox.new self
    @url_handler_list.setTitle "List of registered URL Handlers"
    @url_handler_list_layout = Qt::GridLayout.new
    @url_handler_list.setLayout @url_handler_list_layout

    @refresh = Qt::PushButton.new "Refresh"
    @refresh.connect(SIGNAL :released) {
      refresh
    }

    @list = Qt::ListWidget.new self
    @list.connect(SIGNAL('itemDoubleClicked(QListWidgetItem*)')) { |item|
      @url_open_string.text = item.text + "://"
    }

    @url_handler_list_layout.add_widget @list, 0, 0
    @url_handler_list_layout.add_widget @refresh, 1, 0



    @url_open = Qt::GroupBox.new self
    @url_open.setTitle "Open URL"
    @url_open_layout = Qt::GridLayout.new
    @url_open.setLayout @url_open_layout

    @url_open_string = Qt::LineEdit.new
    @url_open_button = Qt::PushButton.new "Open"
    @url_open_button.connect(SIGNAL :released) {
      $device.open_url @url_open_string.text
    }
    @url_open_layout.addWidget @url_open_string, 0,0
    @url_open_layout.addWidget @url_open_button, 1,0

    layout = Qt::GridLayout.new do |v|
      v.add_widget @url_handler_list, 0, 0
      v.add_widget @url_open, 0, 1
      v.add_widget @fuzz_config, 1, 0, 2, 2

    end
    setLayout(layout)
  end

  def refresh
    @list.clear
    url_handlers = $selected_app.get_url_handlers
    url_handlers.each { |x|
      @list.addItem x
    }
  end

  def clear
    @list.clear
  end
end