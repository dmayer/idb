require_relative 'ssh_port_forward_tab_widget'

class SettingsDialog < Qt::Dialog

  def initialize *args
    super *args
    @layout = Qt::GridLayout.new
    setLayout(@layout)
    setWindowTitle("Settings")


    @save_button = Qt::PushButton.new "Save"
    @save_button.setDefault true

    @save_button.connect(SIGNAL(:released)) {|x|
      $settings["ssh_host"] = @ssh_host.text
      $settings["ssh_port"] = @ssh_port.text
      $settings["ssh_username"] = @ssh_username.text
      $settings["ssh_password"] = @ssh_password.text
      if @usbmux_radio.isChecked
        $settings["device_connection_mode"] = "usb"
      else
        $settings["device_connection_mode"] = "ssh"
      end
      $settings.store
      accept()
    }
    @cancel_button = Qt::PushButton.new "Cancel"
    @cancel_button.connect(SIGNAL(:released)) {|x|
      reject()
    }

    @layout.addWidget @save_button, 2, 1
    @layout.addWidget @cancel_button, 2, 0
    setup_device_config


    forward_config = Qt::GroupBox.new self
    forward_config.setTitle "Port Forwarding"
    forward_config_layout = Qt::GridLayout.new
    forward_config.setLayout forward_config_layout
    @layout.addWidget forward_config, 1, 0, 1,2

    forward_tabs = SSHPortForwardTabWidget.new self
    forward_config_layout.addWidget forward_tabs, 0, 0


    setFixedHeight(sizeHint().height());
  end


  def setup_device_config

    @device_config = Qt::GroupBox.new self
    @device_config.setTitle "Device Configuration"
    @device_config_layout = Qt::GridLayout.new

    @device_config.setLayout(@device_config_layout)
    @layout.addWidget @device_config, 0, 0, 1,2


    @connection_widget = Qt::Widget.new self
    @connection_widget_layout = Qt::GridLayout.new
    @connection_widget.setLayout(@connection_widget_layout)
    @device_config_layout.addWidget @connection_widget, 0, 0, 1, 2

    @ssh_direct_radio = Qt::RadioButton.new @connection_widget
    @ssh_direct_radio.setText("SSH directly")
    @ssh_direct_radio.connect(SIGNAL :released) {
      @ssh_host.setEnabled(true)

    }

    @usbmux_radio = Qt::RadioButton.new @connection_widget
    @usbmux_radio.setText("SSH via USB (usbmuxd)")
    @usbmux_radio.connect(SIGNAL :released) {
      @ssh_host.setEnabled(false)
    }

    @connection_widget_layout.addWidget @ssh_direct_radio, 0,0
    @connection_widget_layout.addWidget @usbmux_radio, 0, 1



    # ssh username
    @label_ssh_username = Qt::Label.new  "SSH Username:", self, 0
    @ssh_username = Qt::LineEdit.new $settings.ssh_username
    @device_config_layout.addWidget @label_ssh_username, 1, 0
    @device_config_layout.addWidget @ssh_username, 1, 1

    # ssh password
    @label_ssh_password = Qt::Label.new  "SSH Password:", self, 0
    @ssh_password = Qt::LineEdit.new  $settings.ssh_password
    @device_config_layout.addWidget @label_ssh_password, 2, 0
    @device_config_layout.addWidget @ssh_password, 2, 1

    # ssh host
    @label_ssh_host = Qt::Label.new  "SSH Host:", self, 0
    @ssh_host = Qt::LineEdit.new  $settings.ssh_host
    @device_config_layout.addWidget @label_ssh_host, 3, 0
    @device_config_layout.addWidget @ssh_host, 3, 1

    # ssh port
    @label_ssh_port = Qt::Label.new  "SSH Port:", self, 0
    @ssh_port = Qt::LineEdit.new  $settings.ssh_port.to_s
    @device_config_layout.addWidget @label_ssh_port, 4, 0
    @device_config_layout.addWidget @ssh_port, 4, 1


    if $settings['device_connection_mode'] == "usb"
      @usbmux_radio.setChecked(true)
      @ssh_host.setEnabled(false)
    end


    if $settings['device_connection_mode'] == "ssh"
      @ssh_direct_radio.setChecked(true)
    end

  end

end
