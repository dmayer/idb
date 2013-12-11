class URLHandlerWidget < Qt::Widget

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