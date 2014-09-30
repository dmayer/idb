module Idb
  class HostFileWrapper

    def initialize
      @cache_path = "tmp/device/hosts"
    end

    def content
      FileUtils.mkpath "tmp/device" unless File.directory? "tmp/device"
      $device.ops.download "/etc/hosts", @cache_path
      begin
        File.open(@cache_path,"r").read
      rescue

      end
    end

    def save text
      # upload
      File.open(@cache_path,"w") { |f|
        f.puts text
      }
      $device.ops.upload(@cache_path, "/etc/hosts")

    end
  end
end