require_relative 'device_status_dialog'

module Idb
  class DeviceInfoGroupBox < Qt::GroupBox
    signals "disconnect()"
    signals "connect_clicked()"

    def initialize(*args)
      super(*args)

      # details on selected app
      @layout = Qt::GridLayout.new
      setLayout(@layout)
      setTitle "Selected Device"

      device_label = "<b><font color='red'>Please select a device from the " \
                     "'Devices' menu or click 'Connect'.</font></b>"
      @device = Qt::Label.new device_label, self, 0
      @layout.addWidget @device, 0, 0, 2, 1
      @connect = Qt::PushButton.new "Connect to USB/SSH device"
      @connect.connect(SIGNAL(:released)) do
        emit connect_clicked
      end
      @layout.addWidget @connect, 0, 1, 2, 1
    end

    def update_device
      if $device.device?
        @connect.hide
        if $device.mode == "usb"
          usb_mode_text = "<b>USB device:</b> Manually connect via SSH as " \
                          "#{$settings.ssh_username}@localhost:#{$device.usb_ssh_port}"
          @device.setText usb_mode_text
        else
          ssh_mode_text = "<b>SSH device:</b> " \
                          "ssh://#{$settings.ssh_username}:[redacted]@" \
                          "#{$settings.ssh_host}:#{$settings.ssh_port}"
          @device.setText ssh_mode_text
        end

        @status = Qt::PushButton.new "Status"
        @status.connect(SIGNAL(:released)) do
          @device_status = DeviceStatusDialog.new
          @device_status.exec
        end
        @layout.addWidget @status, 0, 1

        @disconnect = Qt::PushButton.new "Disconnect"
        @disconnect.connect(SIGNAL(:released)) do
          $device.close unless $device.nil?
          $device = nil
          emit disconnect
          @disconnect.hide
          @connect.show
          @status.hide
          device_selection_text = "<b><font color='red'>Please select a device " \
                                  "from the 'Devices' menu.</font></b>"
          @device.setText(device_selection_text)
        end
        @layout.addWidget @disconnect, 1, 1

      else
        @device.setText "<b>Simulator:</b> #{$device.sim_dir}"
      end
    end
  end
end
