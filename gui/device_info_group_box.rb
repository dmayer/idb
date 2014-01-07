require_relative 'device_status_dialog'

class DeviceInfoGroupBox < Qt::GroupBox


  def initialize *args
    super *args

    # details on selected app
    @layout = Qt::GridLayout.new
    setLayout(@layout)
    setTitle "Selected Device"

    @device = Qt::Label.new  "<b><font color='red'>Please select a device from the 'Devices' menu.</font></b>", self, 0
    @layout.addWidget @device, 0, 0


  end

  def update_device
    if $device.device?
      uname = $device.ops.execute("/bin/uname -a")
      ssh_connection_info = ""
      if $device.mode == "usb"
        ssh_connection_info = " "
        @device.setText "<b>USB device:</b> <b><font color='red'>Manually connect via SSH as #{$settings.ssh_username}@localhost:#{$device.usb_ssh_port}</font></b><br>#{uname}"
      else
        @device.setText "<b>USB device:</b> ssh://#{$settings.ssh_username}:[redacted]@#{$settings.ssh_host}:#{$settings.ssh_port}<br>#{uname}"
      end

      @status = Qt::PushButton.new "Status"
      @status.connect(SIGNAL(:released)) {
        @device_status = DeviceStatusDialog.new
        @device_status.exec
      }
      @layout.addWidget @status, 0, 1

    else
      @device.setText "<b>Simulator:</b> #{$device.sim_dir}"
    end
  end


end