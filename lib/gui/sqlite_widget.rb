require_relative '../lib/console_launcher'

module Idb
  class SqliteWidget  < Qt::Widget

    def initialize *args
      super *args

      @refresh = Qt::PushButton.new "Refresh"
      @refresh.connect(SIGNAL :released) {
        refresh
      }

      @list = Qt::ListWidget.new self
      @list.connect(SIGNAL('itemDoubleClicked(QListWidgetItem*)')) { |item|
        if $settings['sqlite_editor'].nil? or $settings['sqlite_editor'] == ""
          error = Qt::MessageBox.new
          error.setInformativeText("Please configure a SQLite editor in the idb preferences.")
          error.setIcon(Qt::MessageBox::Critical)
          error.exec
        else
          cache_name = $selected_app.cache_file item.full_path
          puts cache_name
          if cache_name.nil?
            $log.error "File #{item.full_path} could not be downloaded. Either the file does not exist (e.g., dead symlink) or there is a permission problem."
          else
            if RbConfig::CONFIG['host_os'] =~ /linux/
              Process.spawn "'#{$settings['sqlite_editor']}' '#{cache_name}'"
            else
              Process.spawn "open -a '#{$settings['sqlite_editor']}' '#{cache_name}'"
            end
          end

          x = ConsoleLauncher.new
          #TODO: find sqlite binary
          #http://www.ruby-doc.org/stdlib-2.0.0/libdoc/mkmf/rdoc/MakeMakefile.html#method-i-find_executable
          #x.run "/usr/bin/sqlite3 #{Dir.getwd}/#{$selected_app.cache_file item.full_path}"
        end



      }
     # "Launch app"

      @default_protection = DefaultProtectionClassGroupWidget.new self
      layout = Qt::VBoxLayout.new do |v|
        v.add_widget(@default_protection)
        v.add_widget(@list)
        v.add_widget(@refresh)
      end
      setLayout(layout)
    end

    def clear
      @list.clear
    end

    def setup
      @list.clear
      @default_protection.update
      item = PathListWidgetItem.new
      item.setText "Please click 'Refresh' below to show files."
      @list.addItem item
      @list.setEnabled false
    end

    def refresh
      @list.clear
      @list.setEnabled true
      @default_protection.update
      sqlite_dbs = $selected_app.find_sqlite_dbs
      sqlite_dbs.each { |full_path|
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