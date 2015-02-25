require_relative '../lib/app'

module Idb

  class AppDetailsGroupBox < Qt::GroupBox
    attr_accessor :uuid, :bundle_id, :vals, :icon
    signals "app_changed()"
    signals "show_device_status()"

    def initialize args
      super *args

      # details on selected app
      @layout = Qt::GridLayout.new
      setLayout(@layout)
      setTitle "App Details"


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
      addDetail 'data_dir', 'Data Directory'

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
      @vals['data_dir'].setText($selected_app.data_directory.sub("/private/var/mobile/Containers/Data/Application",""))
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





    def addDetail id, label
      @labels[id] = Qt::Label.new  "<b>#{label}</b>", self, 0
      @vals[id] = Qt::Label.new  "", self, 0
      @layout.addWidget @labels[id], @cur_row, 0
      @layout.addWidget @vals[id], @cur_row, 1
      @cur_row += 1
    end

  end


  class AppEntitlementsGroupBox < Qt::GroupBox
    def initialize args
      super *args

      # details on selected app

      @layout = Qt::GridLayout.new
      setLayout(@layout)
      setTitle "App Entitlements"

      @labels = Hash.new
      @vals = Hash.new
      clear

      addDetail 'application-identifier', 'Application Identifier'
      @vals['application-identifier'].setText("[No Application Selected]")
    end

    def clear
      @labels.each { |x|
        @layout.removeWidget x[1]
        x[1].destroy
        x[1].dispose
      }

      @vals.each { |x|
        @layout.removeWidget x[1]
        x[1].destroy
        x[1].dispose
      }

      @labels = Hash.new
      @vals = Hash.new
      @cur_row = 1



    end

    def app_changed
      if $device.ios_version < 8
        addDetail 'application-identifier', 'Only available for iOS 8+'
      else
        $selected_app.services_map.entitlements_by_bundle_id($selected_app.bundle_id).each { |x|
          addDetail x[0].to_s, x[0].to_s
          @vals[x[0].to_s].setText(x[1].to_s)
        }
      end

    end


    def addDetail id, label
      @labels[id] = Qt::Label.new  "<b>#{label}</b>", self, 0
      @vals[id] = Qt::Label.new  "", self, 0
      @layout.addWidget @labels[id], @cur_row, 0
      @layout.addWidget @vals[id], @cur_row, 1
      @cur_row += 1
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

      clear

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
