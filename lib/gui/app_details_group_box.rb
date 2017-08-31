require_relative '../lib/app'

module Idb
  class AppDetailsGroupBox < Qt::GroupBox
    attr_accessor :uuid, :bundle_id, :vals, :icon
    signals "app_changed()"
    signals "show_device_status()"

    def initialize(args)
      super(*args)

      # details on selected app
      @layout = Qt::GridLayout.new
      setLayout(@layout)
      setTitle "App Details"

      @labels = {}
      @vals = {}
      @cur_row = 1

      add_detail 'bundle_id', 'Bundle ID'
      add_detail 'bundle_name', 'Bundle Name'
      add_detail 'uuid', 'UUID'
      add_detail 'url_handlers', 'URL Handlers'
      add_detail 'platform_version', 'Platform Version'
      add_detail 'sdk_version', 'SDK Version'
      add_detail 'minimum_os_version', 'Minimum OS'
      add_detail 'data_dir', 'Data Directory'

      @launch_app = Qt::PushButton.new "Launch App"
      @launch_app.setEnabled(false)
      @launch_app.connect(SIGNAL(:released)) do
        if $device.open_installed?
          $selected_app.launch
        else
          msg = "'open' not found on the device. Please visit the status dialog and install it."
          error = Qt::MessageBox.new self
          error.setInformativeText(msg)
          error.setIcon(Qt::MessageBox::Critical)
          error.setMinimumWidth(500)
          error.exec
          emit show_device_status
        end
      end

      @layout.addWidget @launch_app, @cur_row, 0, 1, 2

      @cur_row += 1

      @open_folder = Qt::PushButton.new "Open Local Temp Folder"
      @open_folder.setEnabled(false)
      @layout.addWidget @open_folder, @cur_row, 0, 1, 2

      @open_folder.connect(SIGNAL(:released)) do
        Launchy.open $selected_app.cache_dir
      end

      clear
    end

    def app_changed
      @vals['uuid'].setText($selected_app.uuid)
      @vals['bundle_id'].setText($selected_app.bundle_id)
      @vals['bundle_name'].setText($selected_app.bundle_name)
      @vals['url_handlers'].setText($selected_app.get_url_handlers.join("\n"))
      @vals['platform_version'].setText($selected_app.platform_version)
      @vals['sdk_version'].setText($selected_app.sdk_version)
      @vals['minimum_os_version'].setText($selected_app.minimum_os_version)
      @vals['data_dir'].setText($selected_app.data_directory.sub($device.data_dir,''))
      @launch_app.setEnabled(true)
      @open_folder.setEnabled(true)
    end

    def clear
      $selected_app =  nil
      @vals['uuid'].setText("[No Application Selected]")
      @vals['bundle_id'].setText("[No Application Selected]")
      @vals['bundle_name'].setText("[No Application Selected]")
      @vals['url_handlers'].setText("[No Application Selected]")
      @vals['platform_version'].setText("[No Application Selected]")
      @vals['sdk_version'].setText("[No Application Selected]")
      @vals['minimum_os_version'].setText("[No Application Selected]")
      @vals['data_dir'].setText("[No Application Selected]")
      @launch_app.setEnabled(false)
      @open_folder.setEnabled(false)
    end

    def add_detail(id, label)
      @labels[id] = Qt::Label.new "<b>#{label}</b>", self, 0
      @vals[id] = Qt::Label.new "", self, 0
      @layout.addWidget @labels[id], @cur_row, 0
      @layout.addWidget @vals[id], @cur_row, 1
      @cur_row += 1
    end
  end

  class AppEntitlementsGroupBox < Qt::GroupBox
    def initialize(args)
      super(*args)

      # details on selected app

      @layout = Qt::GridLayout.new
      setLayout(@layout)
      setTitle "App Entitlements"

      @labels = {}
      @vals = {}
      clear

      add_detail 'application-identifier', 'Application Identifier'
      @vals['application-identifier'].setText("[No Application Selected]")
    end

    def clear
      @labels.each do |x|
        @layout.removeWidget x[1]
        x[1].destroy
        x[1].dispose
      end

      @vals.each do |x|
        @layout.removeWidget x[1]
        x[1].destroy
        x[1].dispose
      end

      @labels = {}
      @vals = {}
      @cur_row = 1
    end

    def app_changed
      if $device.ios_version < 8
        add_detail 'application-identifier', 'Only available for iOS 8+'
      else
        $selected_app.entitlements.each do |x|
          add_detail x[0].to_s, x[0].to_s
          @vals[x[0].to_s].setText(x[1].to_s)
        end
      end
    end

    def add_detail(id, label)
      @labels[id] = Qt::Label.new "<b>#{label}</b>", self, 0
      @vals[id] = Qt::Label.new "", self, 0
      @layout.addWidget @labels[id], @cur_row, 0
      @layout.addWidget @vals[id], @cur_row, 1
      @cur_row += 1
    end
  end

  class AppBinaryGroupBox < Qt::GroupBox
    signals "binary_analyzed()"

    def initialize(args)
      super(*args)

      # details on selected app
      @layout = Qt::GridLayout.new
      setLayout(@layout)
      setTitle "App Binary"

      # analyze binary
      @analyze_binary_button = Qt::PushButton.new "Analyze Binary..."
      @analyze_binary_button.setEnabled(false)
      @analyze_binary_button.connect(SIGNAL(:released)) do |_x|
        # TODO: progress bar
        $selected_app.analyze
        @vals['encryption_enabled'].setText($selected_app.binary.encrypted?.to_s)
        @vals['cryptid'].setText($selected_app.binary.cryptid.to_s)
        @vals['pie'].setText($selected_app.binary.pie?.to_s)
        @vals['canaries'].setText($selected_app.binary.stack_protected?.to_s)
        @vals['arc'].setText($selected_app.binary.arc?.to_s)
        emit binary_analyzed
      end
      @layout.addWidget @analyze_binary_button, 0, 0, 1, 2

      @labels = {}
      @vals = {}
      @cur_row = 1

      add_detail 'encryption_enabled', 'Encryption?'
      add_detail 'cryptid', 'Cryptid'
      add_detail 'pie', 'PIE'
      add_detail 'canaries', 'Stack Canaries'
      add_detail 'arc', 'ARC'

      clear
    end

    def add_detail(id, label)
      @labels[id] = Qt::Label.new "<b>#{label}</b>", self, 0
      @vals[id] = Qt::Label.new "", self, 0
      @layout.addWidget @labels[id], @cur_row, 0
      @layout.addWidget @vals[id], @cur_row, 1
      @cur_row += 1
    end

    def app_changed
      clear
      @analyze_binary_button.setEnabled(true)
    end

    def clear
      @vals['encryption_enabled'].setText("[Binary not yet analyzed]")
      @vals['cryptid'].setText("[Binary not yet analyzed]")
      @vals['pie'].setText("[Binary not yet analyzed]")
      @vals['canaries'].setText("[Binary not yet analyzed]")
      @vals['arc'].setText("[Binary not yet analyzed]")
    end

    def disable_analyze_binary
      @analyze_binary_button.setEnabled(false)
    end
  end
end
