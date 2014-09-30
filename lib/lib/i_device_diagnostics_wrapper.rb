require 'ffi'

module IMobileDevice
  extend FFI::Library

  ffi_lib 'libimobiledevice'
  IDeviceEventType = enum(
      :idevice_device_added, 1,
      :idevice_device_remove
  )

  class IDeviceEventT < FFI::Struct
    layout :event, IDeviceEventType,
           :udid, :string,
           :conn_type, :int
  end

  ConnectionType = enum(
      :connection_usbmuxd,  1
  )

  class IDevicePrivate < FFI::Struct
    layout :udid, :string,
           :conn_type, ConnectionType,
           :conn_data, :pointer
  end



  attach_function :idevice_get_device_list, [:pointer, :pointer], :int
  attach_function :idevice_event_subscribe, [:pointer, :pointer], :int
  attach_function :idevice_new, [:pointer, :string], :int
#  attach_function :syslog_relay_client_start_service, [IDevicePrivate, :pointer, :string], :int
#  attach_function :syslog_relay_start_capture, [:pointer, :pointer, :pointer],  :int
#  attach_function :syslog_relay_client_free, [:pointer], :int

  def self.startLogging
    ret = idevice_new(IDevicePrivate, @udid)
    if ret != 0
      puts "ERROR"
    end




  end
  def self.stopLogging
    puts "stopstopstop"

  end

#  DeviceEvn :device, [:pointer, :long, :uint8], :void

  DeviceEventCB = FFI::Function.new(:void, [:pointer, :pointer]) do |event, userdata|
    # cast event to struct
    event_t = IDeviceEventT.new event
    if event_t[:event] == :idevice_device_added
      if @syslog.nil? or @syslog == false
        if @udid.nil? or @udid == false
          @udid = event_t[:udid]
        end

        if @udid == event_t[:udid]
          #TODO error checking
          puts "[*] Start Logging"
          IMobileDevice.startLogging
        end
      end
    elsif avent_t[:event] == :idevice_device_remove
      if not @syslog.nil? and @udid == event_t[:udid]
        puts "[*] Disconnected"
      end
    end
  end
end

devices = FFI::MemoryPointer.new :pointer
num = FFI::MemoryPointer.new :int
x = IMobileDevice.idevice_get_device_list(devices, num)
device =  devices.read_pointer.get_array_of_string(0,num.read_int).first
puts "Device #{device}"
IMobileDevice.idevice_event_subscribe(IMobileDevice::DeviceEventCB, nil)



while true

end


