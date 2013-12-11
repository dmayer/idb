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

        #icon_file = $selected_app.cache_file($selected_app.icon_path) unless $selected_app.icon_path.nil?
        #@icon.setPixmap Qt::Pixmap.new(":/#{icon_file}") unless icon_file.nil?

        emit app_changed()
      }

      @app_list.exec
    }


    @icon_button_widget = Qt::Widget.new self
    @icon_button_widget.setLayout @icon_button_layout

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
        error.setInformativeText("<p>Need to install additional software in order to launch app...</p>")
        error.setIcon(Qt::MessageBox::Information)
        error.setMinimumWidth(500)
        error.exec
        emit show_device_status()
      end
    }

    @layout.addWidget @launch_app, @cur_row, 0, 1, 2


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
      emit binary_analyzed()
    }
    @layout.addWidget @analyze_binary_button, 0, 0, 1, 2

    @labels = Hash.new
    @vals = Hash.new
    @cur_row = 1

    addDetail 'encryption_enabled', 'Encryption?'
    addDetail 'cryptid', 'Cryptid'

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
  end




end
