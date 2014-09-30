require_relative 'ca_interface'

module Idb
  class DeviceCAInterface < CAInterface

    def initialize device
      @device = device
      @device_store_path = "/private/var/Keychains/TrustStore.sqlite3"
      base_path = "tmp/device"
      FileUtils.mkdir_p base_path
      @db_path = "#{base_path}/TrustStore.sqlite3"


    end


    def get_certs
      @device.ops.download @device_store_path, @db_path
      super
    end

    def remove_cert cert
      FileUtils.copy_file @db_path, "#{@db_path}-#{Time.now.to_s}"
      super cert
      @device.ops.upload @db_path, @device_store_path
    end

    def add_cert cert_file
      FileUtils.copy_file @db_path, "#{@db_path}-#{Time.now.to_s}"
      super cert_file
      @device.ops.upload @db_path, @device_store_path
    end


  end
end