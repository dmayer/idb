require_relative 'ssh_port_forward_tab_widget'

class SettingsTabWidget < Qt::TabWidget
  attr_accessor :ssh_host, :ssh_port, :ssh_username, :ssh_password, :usbmux_radio, :manual_ssh_port, :idb_utility_port
  attr_accessor :sqlite_editor

  def initialize *args
    super *args

    setup_device_config
    addTab @device_config_tab, "Device Config"
    setup_forwards
    addTab @forward_config, "Port Forwarding"
    setup_external_apps
    addTab @external_apps_config, "External Editors"

  end

  def setup_device_config
    @device_config_tab = Qt::Widget.new self
    device_config_layout = Qt::GridLayout.new
    @device_config_tab.setLayout device_config_layout

    device_config_layout.addWidget @device_config, 0, 0, 1,2


    @connection_widget = Qt::Widget.new self
    @connection_widget_layout = Qt::GridLayout.new
    @connection_widget.setLayout(@connection_widget_layout)
    device_config_layout.addWidget @connection_widget, 0, 0, 1, 2

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
    device_config_layout.addWidget @label_ssh_username, 1, 0
    device_config_layout.addWidget @ssh_username, 1, 1

    # ssh password
    @label_ssh_password = Qt::Label.new  "SSH Password:", self, 0
    @ssh_password = Qt::LineEdit.new  $settings.ssh_password
    device_config_layout.addWidget @label_ssh_password, 2, 0
    device_config_layout.addWidget @ssh_password, 2, 1

    # ssh host
    @label_ssh_host = Qt::Label.new  "SSH Host:", self, 0
    @ssh_host = Qt::LineEdit.new  $settings.ssh_host
    device_config_layout.addWidget @label_ssh_host, 3, 0
    device_config_layout.addWidget @ssh_host, 3, 1

    # ssh port
    @label_ssh_port = Qt::Label.new  "SSH Port:", self, 0
    @ssh_port = Qt::LineEdit.new  $settings.ssh_port.to_s
    device_config_layout.addWidget @label_ssh_port, 4, 0
    device_config_layout.addWidget @ssh_port, 4, 1


    if $settings['device_connection_mode'] == "usb"
      @usbmux_radio.setChecked(true)
      @ssh_host.setEnabled(false)
    end


    if $settings['device_connection_mode'] == "ssh"
      @ssh_direct_radio.setChecked(true)
    end

  end

  def setup_forwards

    @forward_config = Qt::Widget.new self
    forward_config_layout = Qt::GridLayout.new
    @forward_config.setLayout forward_config_layout

    @forward_tabs = SSHPortForwardTabWidget.new self
    forward_config_layout.addWidget @forward_tabs, 0, 0, 1, 2

    # manual SSH port
    @label_manual_ssh_port = Qt::Label.new  "Port for Manual SSH:", self, 0
    @manual_ssh_port = Qt::LineEdit.new  $settings.manual_ssh_port.to_s
    forward_config_layout.addWidget @label_manual_ssh_port, 2, 0
    forward_config_layout.addWidget @manual_ssh_port, 2, 1

    # idb utility forward port
    @label_idb_utility_port = Qt::Label.new  "Port for internal idb operations:", self, 0
    @idb_utility_port = Qt::LineEdit.new  $settings.idb_utility_port.to_s
    forward_config_layout.addWidget @label_idb_utility_port, 3, 0
    forward_config_layout.addWidget @idb_utility_port, 3, 1

  end

  def setup_external_apps
    @external_apps_config = Qt::Widget.new self
    external_apps_config_layout = Qt::GridLayout.new
    @external_apps_config.setLayout external_apps_config_layout








    # sqlite editor
    @label_sqlite_editor = Qt::Label.new  "SQLite Editor:", self, 0
    @sqlite_editor = Qt::Label.new  $settings.sqlite_editor
    @sqlite_editor_change = Qt::PushButton.new "Change"

    @sqlite_editor_change.connect(SIGNAL :released) {
      file_dialog = Qt::FileDialog.new
      file_dialog.setAcceptMode(Qt::FileDialog::AcceptOpen)

      file_dialog.connect(SIGNAL('fileSelected(QString)')) { |x|
        @sqlite_editor.setText x
      }
      file_dialog.exec
    }
    external_apps_config_layout.addWidget @label_sqlite_editor, 1, 0
    external_apps_config_layout.addWidget @sqlite_editor, 1, 1
    external_apps_config_layout.addWidget @sqlite_editor_change, 1, 2

  end

  def forwarders_changed?
    @forward_tabs.forwarders_changed?
  end


end