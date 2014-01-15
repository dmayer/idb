require_relative 'settings_tab_widget'



class SettingsDialog < Qt::Dialog

  def initialize *args
    super *args

    @layout = Qt::GridLayout.new
    setLayout(@layout)
    setWindowTitle("Settings")

    @tabs = SettingsTabWidget.new self
    @layout.addWidget @tabs, 0,0,1,2

    @save_button = Qt::PushButton.new "Save"
    @save_button.setDefault true

    @save_button.connect(SIGNAL(:released)) {|x|
      $settings["ssh_host"] = @tabs.ssh_host.text
      $settings["ssh_port"] = @tabs.ssh_port.text
      $settings["ssh_username"] = @tabs.ssh_username.text
      $settings["ssh_password"] = @tabs.ssh_password.text

      if @tabs.usbmux_radio.isChecked
        $settings["device_connection_mode"] = "usb"
      else
        $settings["device_connection_mode"] = "ssh"
      end

      $settings["manual_ssh_port"] = @tabs.manual_ssh_port.text
      $settings["sqlite_editor"] = @tabs.sqlite_editor.text

      $settings.store

      if not $device.nil? and  forwarders_changed?
        reply = Qt::MessageBox::question(self, "Reload Port Forwards", "Portforwarding has changed. Do you want to apply the new configuration?<br>(This may interrupt existing connections)", Qt::MessageBox::Yes, Qt::MessageBox::No);
        if reply == Qt::MessageBox::Yes
          $device.restart_port_forwarding
        end
      end

      accept()
    }
    @cancel_button = Qt::PushButton.new "Cancel"
    @cancel_button.connect(SIGNAL(:released)) {|x|
      reject()
    }

    @layout.addWidget @save_button, 2, 1
    @layout.addWidget @cancel_button, 2, 0






  end
#
  def forwarders_changed?
    @tabs.forwarders_changed?
  end



end
