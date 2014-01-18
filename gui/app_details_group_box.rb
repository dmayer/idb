require_relative '../lib/app'

class AppDetailsGroupBox < Qt::GroupBox
  attr_accessor :uuid, :bundle_id
  signals "app_changed()"
  signals "show_device_status()"

  def initialize args
    super *args

    # details on selected app
    @layout = Qt::GridLayout.new
    setLayout(@layout)
    setTitle "App Details"


    @icon_button_layout = Qt::GridLayout.new


    # select app
    @select_app_button = Qt::PushButton.new "Select App..."
    @select_app_button.setEnabled(false)
    @select_app_button.connect(SIGNAL(:released)) { |x|
      @app_list = AppListDialog.new
      @app_list.connect(SIGNAL('accepted()')) {
        $selected_app =  @app_list.app_list.currentItem().app
        @vals['uuid'].setText($selected_app.uuid)
        @vals['bundle_id'].setText($selected_app.bundle_id)
        @vals['bundle_name'].setText($selected_app.bundle_name)
        @vals['url_handlers'].setText($selected_app.get_url_handlers.join("\n"))
        @vals['platform_version'].setText($selected_app.platform_version)
        @vals['sdk_version'].setText($selected_app.sdk_version)
        @vals['minimum_os_version'].setText($selected_app.minimum_os_version)
        @launch_app.setEnabled(true)
        @open_folder.setEnabled(true)

        begin
        icon_file = $selected_app.get_icon_file
        pixmap = Qt::Pixmap.new(icon_file)
        @icon.setPixmap pixmap.scaledToWidth(50)  unless icon_file.nil?

        rescue => e
          $log.error "Icon CONVERSION failed.  #{e.message}"
          @icon.setPixmap Qt::Pixmap.new
          # lets ignore conversion errors for now..
        end


        emit app_changed()
      }

      @app_list.exec
    }


    @icon_button_widget = Qt::Widget.new self
    @icon_button_widget.setLayout @icon_button_layout

    @icon = Qt::Label.new

    @icon_button_layout.addWidget @icon, 0, 0, 1, 1
    @icon_button_layout.addWidget @select_app_button, 0, 1, 1, 3
    @layout.addWidget @icon_button_widget, 0, 0, 1, 2




    @labels = Hash.new
    @vals = Hash.new
    @cur_row = 1

    addDetail 'bundle_id', 'Bundle ID'
    addDetail 'bundle_name', 'Bundle Name'
    addDetail 'uuid', 'UUID'
    addDetail 'url_handlers', 'URL Handlers'
    addDetail 'platform_version', 'Platform Version'
    addDetail 'sdk_version', 'SDK Version'
    addDetail 'minimum_os_version', 'Minimum OS'

    @launch_app = Qt::PushButton.new "Launch App"
    @launch_app.setEnabled(false)
    @launch_app.connect(SIGNAL(:released)) {
      if $device.open_installed?
        $selected_app.launch
      else
        error = Qt::MessageBox.new self
        error.setInformativeText("'open' not found on the device. Please visit the status dialog and install it.")
        error.setIcon(Qt::MessageBox::Critical)
        error.setMinimumWidth(500)
        error.exec
        emit show_device_status()
      end
    }

    @layout.addWidget @launch_app, @cur_row, 0, 1, 2

    @cur_row+=1

    @open_folder = Qt::PushButton.new "Open Local Temp Folder"
    @open_folder.setEnabled(false)
    @layout.addWidget @open_folder, @cur_row, 0, 1, 2

    @open_folder.connect(SIGNAL :released) {
      Launchy.open $selected_app.cache_dir

    }

  end


  def addDetail id, label
    @labels[id] = Qt::Label.new  "<b>#{label}</b>", self, 0
    @vals[id] = Qt::Label.new  "", self, 0
    @layout.addWidget @labels[id], @cur_row, 0
    @layout.addWidget @vals[id], @cur_row, 1
    @cur_row += 1
  end


  def enable_select_app
    @select_app_button.setEnabled(true)
  end

end

class AppBinaryGroupBox < Qt::GroupBox
  signals "binary_analyzed()"

  def initialize args
    super *args

    # details on selected app
    @layout = Qt::GridLayout.new
    setLayout(@layout)
    setTitle "App Binary"


    # analyze binary
    @analyze_binary_button = Qt::PushButton.new "Analyze Binary..."
    @analyze_binary_button.setEnabled(false)
    @analyze_binary_button.connect(SIGNAL(:released)) { |x|
      #TODO progress bar
      $selected_app.analyze
      @vals['encryption_enabled'].setText($selected_app.binary.is_encrypted?.to_s)
      @vals['cryptid'].setText($selected_app.binary.get_cryptid.to_s)
      @vals['pie'].setText($selected_app.binary.is_pie?.to_s)
      @vals['canaries'].setText($selected_app.binary.is_stack_protected?.to_s)
      @vals['arc'].setText($selected_app.binary.uses_arc?.to_s)
      emit binary_analyzed()
    }
    @layout.addWidget @analyze_binary_button, 0, 0, 1, 2

    @labels = Hash.new
    @vals = Hash.new
    @cur_row = 1

    addDetail 'encryption_enabled', 'Encryption?'
    addDetail 'cryptid', 'Cryptid'
    addDetail 'pie', 'PIE'
    addDetail 'canaries', 'Stack Canaries'
    addDetail 'arc', 'ARC'

  end


  def addDetail id, label
    @labels[id] = Qt::Label.new  "<b>#{label}</b>", self, 0
    @vals[id] = Qt::Label.new  "", self, 0
    @layout.addWidget @labels[id], @cur_row, 0
    @layout.addWidget @vals[id], @cur_row, 1
    @cur_row += 1
  end

  def app_changed
    clear
    @analyze_binary_button.setEnabled(true)
  end

  def clear
    @vals['encryption_enabled'].setText("")
    @vals['cryptid'].setText("")
    @vals['pie'].setText("")
    @vals['canaries'].setText("")
    @vals['arc'].setText("")
  end




end
