
module Idb
  class AppListDialog < Qt::Dialog
    attr_accessor :app_list

    def initialize *args
      super *args

      setWindowTitle("App Selection")
      @layout = Qt::GridLayout.new
      setLayout(@layout)

      @app_list = Qt::ListWidget.new self
      @app_list.setSortingEnabled(true);
      @app_list.connect(SIGNAL('itemDoubleClicked(QListWidgetItem*)')) { |item|
        emit accept
      }
      @layout.addWidget @app_list, 0, 0, 1, 2



      @save_button = Qt::PushButton.new "Select"
      @save_button.setDefault true

      @save_button.connect(SIGNAL(:released)) {|x|
        accept()
      }
      @cancel_button = Qt::PushButton.new "Cancel"
      @cancel_button.connect(SIGNAL(:released)) {|x|
        reject()
      }

      unless refresh_app_list
        @save_button.setEnabled(false)
      end

      @layout.addWidget @save_button, 1, 1
      @layout.addWidget @cancel_button, 1, 0

      setFixedHeight(500);
      setFixedWidth(400);


    end

    def refresh_app_list
      if $device.ios_version >= 8
        box = Qt::MessageBox.new 1, "Refreshing...", "Refreshing uicache to ensure app information is up-to-date. This may take a few seconds."
        box.setStandardButtons(0)
        box.show
        box.raise
        # need to refresh iOS uicache in case app was installed after last reboot.
        # Otherwise the /var/mobile/Library/MobileInstallation/LastLaunchServicesMap.plist will be out of date
        $device.ops.execute "/bin/su mobile -c /usr/bin/uicache"
        box.hide
      end

      begin
        app_uuids =  $device.get_app_uuids
      rescue Exception => e
        error = Qt::MessageBox.new
        error.setInformativeText("Unable to get list of applications. Ensure that you have at least one non-system app installed.")
        error.setIcon(Qt::MessageBox::Critical)
        error.exec
        return false
      end

      progress = Qt::ProgressDialog.new "Reading App list...", nil, 1, app_uuids.size, self
      progress.setAutoClose true
      progress.setWindowModality(Qt::WindowModal);
      progress.show
      progress.raise


      app_uuids.each { |uuid|
        a = App.new uuid

        i = AppListWidgetItem.new @app_list, 0
        i.setText (a.bundle_id.to_s + " => " + a.bundle_name.to_s)
        i.app = a
        @app_list.add_item i
        progress.setValue(progress.value+1);


      }
    end


  end
end
