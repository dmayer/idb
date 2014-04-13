class HostFileWrapper

  def initialize
    @cache_path = "tmp/device/hosts"
  end

  def content
    $device.ops.download "/etc/hosts", @cache_path
    File.open(@cache_path,"r").read
  end

  def save text
    # upload
    File.open(@cache_path,"w") { |f|
      f.puts text
    }
    $device.ops.upload(@cache_path, "/etc/hosts")

  end
end