require_relative 'path_list_widget_item'

module Idb
  class PlistFileWidget < Qt::Widget

    def initialize *args
      super *args

      @refresh = Qt::PushButton.new "Refresh"
      @refresh.connect(SIGNAL :released) {
        refresh
      }


      @list = Qt::ListWidget.new self
      @list.connect(SIGNAL('itemDoubleClicked(QListWidgetItem*)')) { |item|
        cache_name =  $selected_app.cache_file item.full_path
        if cache_name.nil?
          $log.error "File #{item.full_path} could not be downloaded. Either the file does not exist (e.g., dead symlink) or there is a permission problem."
        else
          $device.ops.open cache_name
        end
      }
  #    @list.setContextMenuPolicy(Qt::CustomContextMenu);
  #    @list.connect(SIGNAL('customContextMenuRequested(QPoint)')) { |item|
  #      menu = Qt::Menu.new("Context menu", self)
  #      menu.addAction(Qt::Action.new("Hello", self));
  #      menu.exec(mapToGlobal(pos));
  #
  #    }


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
        if $device.simulator?
          item.setText full_path.sub($selected_app.app_dir,'')
        else
          pc = $device.protection_class full_path
          if full_path.start_with? $selected_app.app_dir
            item.setText "[App Bundle]" + full_path.sub($selected_app.app_dir,'') + " => " + pc.strip
          elsif full_path.start_with? $selected_app.data_dir
             item.setText "[Data Dir]" + full_path.sub($selected_app.data_dir,'') + " => " + pc.strip
          end
        end
        item.full_path = full_path
        @list.addItem item
      }
    end




  end
end