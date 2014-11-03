module Idb
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

        cache_name = $selected_app.cache_file item.full_path
        if cache_name.nil?
          $log.error "File #{item.full_path} could not be downloaded. Either the file does not exist (e.g., dead symlink) or there is a permission problem."
        else
          if RbConfig::CONFIG['host_os'] =~ /linux/
            Process.spawn "'#{$settings['sqlite_editor']}' '#{cache_name}'"
          else
            Process.spawn "open -a '#{$settings['sqlite_editor']}' '#{cache_name}'"
          end
        end

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
        if $device.simulator?
          item.setText full_path.sub($selected_app.app_dir,'')
        else
          pc = $device.protection_class full_path
          item.setText full_path.sub($selected_app.app_dir,'') + " => " + pc.strip
        end
        item.full_path = full_path
        @list.addItem item
      }
    end

  end
end