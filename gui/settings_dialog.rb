

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
    setup_port_forward

    setFixedHeight(sizeHint().height());
  end

  def add_remote_forward_to_list remote_port, local_port, local_host
    @forward_list.addItem Qt::ListWidgetItem.new "remote:#{remote_port} -> #{local_host}:#{local_port}"

  end

  def setup_port_forward
    @forward_config = Qt::GroupBox.new self
    @forward_config.setTitle "Port Forwarding"

    @forward_config_layout = Qt::GridLayout.new

    @forward_config.setLayout(@forward_config_layout)
    @layout.addWidget @forward_config, 1, 0, 1,2

    @forward_list = Qt::ListWidget.new @forward_config
    @forward_config_layout.addWidget @forward_list, 0, 0, 2, 2


    if $settings['remote_forwards'].nil?
      $settings['remote_forwards'] = Array.new
    end

    $settings['remote_forwards'].each {|x|
      add_remote_forward_to_list x['remote_port'], x['local_port'], x['local_host']
    }


    @add_forward_button = Qt::PushButton.new "Add"
    @add_forward_button.connect(SIGNAL(:released)) {
      remote_port = @remote_port_text.text
      local_port = @local_port_text.text
      local_host = @local_host_text.text

      if is_valid_port(remote_port) and is_valid_port(local_port)
        add_remote_forward_to_list remote_port, local_port, local_host

        item = Hash.new
        item['remote_port'] = @remote_port_text.text
        item['local_port'] = @local_port_text.text
        item['local_host'] = @local_host_text.text
        $settings['remote_forwards'] << item
        $settings.store


        @remote_port_text.text = ""
        @local_port_text.text = ""
        @local_host_text.text = ""
      end
    }
    @remove_forward_button = Qt::PushButton.new "Remove"
    @remove_forward_button.connect(SIGNAL(:released)) {
      if not @forward_list.current_row.nil?
        row = @forward_list.current_row
        @forward_list.takeItem  row
        $settings['local_forwards'].delete_at(row)
        $settings.store
      end

    }

    @forward_config_layout.addWidget @add_forward_button, 0, 3
    @forward_config_layout.addWidget @remove_forward_button, 1, 3

    @remote_port_label = Qt::Label.new "Remote Port"
    @remote_port_text = Qt::LineEdit.new


    @local_host_label = Qt::Label.new "Local Destination"
    @local_host_text = Qt::LineEdit.new


    @local_port_label = Qt::Label.new "Local Port"
    @local_port_text = Qt::LineEdit.new

    @forward_config_layout.addWidget @remote_port_label, 2, 0
    @forward_config_layout.addWidget @remote_port_text, 2, 1


    @forward_config_layout.addWidget @local_host_label, 3, 0
    @forward_config_layout.addWidget @local_host_text, 3, 1


    @forward_config_layout.addWidget @local_port_label, 4, 0
    @forward_config_layout.addWidget @local_port_text, 4, 1

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


  def is_valid_port port
    begin
      if not Integer(port) or Integer(port) > 2**16 or Integer(port) < 1
        return false
      else
        return true
      end
    rescue
      false
    end
  end

end
