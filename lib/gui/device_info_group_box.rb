require_relative 'device_status_dialog'

module Idb
  class DeviceInfoGroupBox < Qt::GroupBox
    signals "disconnect()"
    signals "connect_clicked()"

    def initialize *args
      super *args

      # details on selected app
      @layout = Qt::GridLayout.new
      setLayout(@layout)
      setTitle "Selected Device"

      @device = Qt::Label.new  "<b><font color='red'>Please select a device from the 'Devices' menu or click 'Connect'.</font></b>", self, 0
      @layout.addWidget @device, 0, 0, 2 ,1
      @connect = Qt::PushButton.new "Connect to USB/SSH device"
      @connect.connect(SIGNAL(:released)) {
        emit connect_clicked()
      }
      @layout.addWidget @connect, 0,1,2,1
    end

    def update_device
      if $device.device?
        @connect.hide
        uname = $device.ops.execute("/bin/uname -a")
        ssh_connection_info = ""
        if $device.mode == "usb"
          ssh_connection_info = " "
          @device.setText "<b>USB device:</b> Manually connect via SSH as #{$settings.ssh_username}@localhost:#{$device.usb_ssh_port}"
        else
          @device.setText "<b>SSH device:</b> ssh://#{$settings.ssh_username}:[redacted]@#{$settings.ssh_host}:#{$settings.ssh_port}"
        end

        @status = Qt::PushButton.new "Status"
        @status.connect(SIGNAL(:released)) {
          @device_status = DeviceStatusDialog.new
          @device_status.exec
        }
        @layout.addWidget @status, 0, 1

        @disconnect = Qt::PushButton.new "Disconnect"
        @disconnect.connect(SIGNAL(:released)) {
          $device.close unless $device.nil?
          $device = nil
          emit disconnect()
          @disconnect.hide
          @connect.show
          @status.hide
          @device.setText("<b><font color='red'>Please select a device from the 'Devices' menu.</font></b>")
        }
        @layout.addWidget @disconnect, 1, 1


      else
        @device.setText "<b>Simulator:</b> #{$device.sim_dir}"
      end
    end


  end
end