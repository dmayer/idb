require_relative 'plist_util'
require_relative 'app_binary'
require_relative 'CgBI'

class App
  attr_accessor :uuid, :app_dir, :binary

  def initialize uuid
    @uuid = uuid
    @app_dir = "#{$device.apps_dir}/#{@uuid}"
    @cache_dir = "tmp/#{uuid}"
    FileUtils.mkdir_p @cache_dir  unless Dir.exist? @cache_dir
    parse_info_plist
  end

  def analyze
    local_binary_path = cache_file binary_path
    @binary = AppBinary.new local_binary_path
    if @binary.is_encrypted?
      $log.info "Binary is encrypted. Decrypting for further analysis."
      decrypt_binary!
    end
  end


  def decrypt_binary!
    unless $device.dumpdecrypted_installed?
      $log.error "dumpdecrypted not installed."
      return false
    end

    $log.info "Running '#{binary_path}'"
    full_remote_path = binary_path

    $device.ops.execute "cd /var/root/"
    $device.ops.execute "DYLD_INSERT_LIBRARIES=dumpdecrypted.dylib \"#{full_remote_path}\""

    decrypted_path = "/var/root/#{File.basename full_remote_path}.decrypted"
    $log.info "Checking if decrypted file #{decrypted_path} was created..."
    if not $device.ops.file_exists? decrypted_path
      $log.error "Decryption failed. File may not be encrypted."
      return
    end

    $log.info "Decrypted file found. Downloading..."

    local_decrypted_binary = "#{cache_dir}/#{File.basename full_remote_path}.decrypted"
    @binary.setDecryptedPath local_decrypted_binary

    local_path = $device.ops.download decrypted_path, local_decrypted_binary

    $log.info "Decrypted binary downloaded to #{local_decrypted_binary}"
    local_decrypted_binary

  end




  def get_raw_plist_value val
    begin
      @info_plist.plist_data[val]
    rescue
      "[error]"
    end
  end


  def icon_path
    icon_name = get_raw_plist_value('CFBundleIconFiles').first
    app_dir = Shellwords.escape(@app_dir)

    unless (icon_name[-4,4] == ".png")
      $log.debug "Appending extension to #{icon_name}"
      icon_name += ".png"
      $log.debug "Now: #{icon_name}"
    end

    icon_file = $device.ops.execute("ls #{app_dir}/*app/#{icon_name}").strip

    if not $device.ops.file_exists? icon_file
      $log.warn "Icon not found: #{icon_file}"
      return nil
    end
    $log.info "Icon found at #{icon_file}"
    return icon_file
  end

  def get_icon_file
    path = icon_path
    unless path.nil?
      local_path = cache_file path
      new_local_path = "#{local_path}.png"
      CGBI.from_file(local_path).to_png_file(new_local_path)
      new_local_path
    else
      nil
    end
  end

  def bundle_name
    get_raw_plist_value 'CFBundleDisplayName'
  end

  def platform_version
    get_raw_plist_value 'DTPlatformVersion'
  end

  def sdk_version
    get_raw_plist_value 'DTSDKName'
  end

  def minimum_os_version
    get_raw_plist_value 'MinimumOSVersion'
  end

  def bundle_id
    begin
      @info_plist.bundle_identifier
    rescue
      "[error]"
    end
  end

  def launch
      $device.app_launch self
  end

  def binary_path
    $log.info "Locating application binary..."
    dirs = $device.ops.dir_glob("#{@app_dir}/","**")
    dirs.select! { |f|
      $device.ops.file_exists? "#{f}/#{binary_name}"
    }

    "#{dirs.first}/#{binary_name}"
  end

  def binary_name
    begin
      @info_plist.binary_name
    rescue
      "[error]"
    end
  end

  def find_plist_files
    puts "[*] Looking for plist files..."
    $device.ops.dir_glob(@app_dir, "**/*plist")
  end

  def find_sqlite_dbs
    puts "[*] Looking for sqlite files..."
    $device.ops.dir_glob(@app_dir, "**/*sqlite")
  end

  def find_cache_dbs
    puts "[*] Looking for Cache.db files..."
    $device.ops.dir_glob(@app_dir, "**/Cache.db")
  end

  def get_url_handlers
    @info_plist.schemas
  end

  def cache_dir
   "tmp/#{@uuid}/"
  end


  def cache_file f
    relative_file = f.sub(@app_dir,'')
    relative_dir = File.dirname relative_file
    cache_dir = "tmp/#{@uuid}/#{relative_dir}"
    FileUtils.mkdir_p(cache_dir) unless Dir.exist?(cache_dir)
    cached_file_path = "#{cache_dir}/#{File.basename(f)}"

    if $device.ops.download f, cached_file_path
      return cached_file_path
    else
      return nil
    end
  end
  private

  def parse_info_plist
    begin
      plist_file = cache_file(info_plist_path)
      @info_plist = PlistUtil.new plist_file
      @info_plist.parse_info_plist
    rescue
      $log.error "Error getting plist file #{info_plist_path}"
    end
  end



  def info_plist_path
    app_dir = Shellwords.escape(@app_dir)
    plist_file = $device.ops.execute("ls #{app_dir}/*app/Info.plist").strip

    # the following works but is terribly slow.
    #plist_file = (@if.ops.dir_glob "#{@app_dir}/","*app/Info.plist").first

    if not $device.ops.file_exists? plist_file
      $log.error "Info.plist not found."
      return nil
    end
    $log.info "Info.plist found at #{plist_file}"
    return plist_file
  end
end
