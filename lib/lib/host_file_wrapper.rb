module Idb
  class HostFileWrapper
    def initialize
      @cache_path = "#{$tmp_path}/device/hosts"
    end

    def content
      FileUtils.mkpath "#{$tmp_path}/device" unless File.directory? "#{$tmp_path}/device"
      $device.ops.download "/etc/hosts", @cache_path
      begin
        File.open(@cache_path, "r").read
      rescue
        $log.error "Could not open #{@cache_path}"
      end
    end

    def save(text)
      # upload
      File.open(@cache_path, "w") do |f|
        f.puts text
      end
      $device.ops.upload(@cache_path, "/etc/hosts")
    end
  end
end
