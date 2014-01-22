class SharedLibrariesWidget < Qt::Widget
    def initialize *args
      super *args

      @refresh = Qt::PushButton.new "Refresh"
      @refresh.connect(SIGNAL :released) {
        refresh
      }

      @list = Qt::ListWidget.new self

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
      if not $selected_app.binary.nil?
        shared_lib = $selected_app.binary.get_shared_libraries
        if shared_lib.nil?
          item = Qt::ListWidgetItem.new
          item.setText "Error: otool required"
          @list.addItem item
          return
        end
        shared_lib.each { |lib|
          item = Qt::ListWidgetItem.new
          item.setText lib
          @list.addItem item
        }
        setEnabled(true)
      else
        setEnabled(false)
      end

    end

end
