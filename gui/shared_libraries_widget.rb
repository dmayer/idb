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
      puts "Refreshing"
      @list.clear
      if not $selected_app.binary.nil?
        puts "ENABLED"
        shared_lib = $selected_app.binary.get_shared_libraries
        shared_lib.each { |lib|
          item = Qt::ListWidgetItem.new
          item.setText lib
          @list.addItem item
        }
        setEnabled(true)
      else
        puts "DISABLED"
        setEnabled(false)
      end

    end

end
