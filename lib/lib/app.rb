require_relative 'plist_util'
require_relative 'app_binary'
require_relative 'CgBI'
require_relative 'ios8_last_launch_services_map_wrapper'

module Idb
  class App
    attr_accessor :uuid, :app_dir, :binary, :cache_dir, :data_dir


    def initialize uuid
      @uuid = uuid
      @cache_dir = "#{$tmp_path}/#{uuid}"
      FileUtils.mkdir_p @cache_dir  unless Dir.exist? @cache_dir

      @app_dir = "#{$device.apps_dir}/#{@uuid}"
      parse_info_plist

      if $device.ios_version == 8
        mapping_file = "/var/mobile/Library/MobileInstallation/LastLaunchServicesMap.plist"
        local_mapping_file =  cache_file mapping_file
        mapper = IOS8LastLaunchServicesMapWrapper.new local_mapping_file

        @data_dir = mapper.data_path_by_bundle_id @info_plist.bundle_identifier
        @keychain_access_groups = mapper.keychain_access_groups_by_bundle_id @info_plist.bundle_identifier

       else
        @data_dir = @app_dir
      end


    end

    def analyze
      local_binary_path = cache_file binary_path
      @binary = AppBinary.new local_binary_path
      if @binary.is_encrypted?
        $log.info "Binary is encrypted. Decrypting for further analysis."
        decrypt_binary!
      else
        $log.info "Binary is not encrypted."
        @local_decrypted_binary = local_binary_path
      end
    end

    def strings
      data = `strings '#{@local_decrypted_binary}'`
    end

    def decrypt_binary!
      unless $device.dumpdecrypted_installed?
        $log.error "dumpdecrypted not installed."
        return false
      end

      dylib = "dumpdecrypted_#{$device.arch}.dylib"

      $log.info "Running '#{binary_path}'"
      full_remote_path = binary_path
      decrypted_path = "/var/root/#{File.basename full_remote_path}.decrypted"

      $device.ops.execute "cd /var/root/"
      $device.ops.execute "DYLD_INSERT_LIBRARIES=dumpdecrypted_armv7.dylib \"#{full_remote_path}\""
      $log.info "Checking if decrypted file #{decrypted_path} was created..."
      if not $device.ops.file_exists? decrypted_path
        $log.error "Decryption failed. Trying armv6 build for iOS 6 and earlier..."
        $device.ops.execute "DYLD_INSERT_LIBRARIES=dumpdecrypted_armv6.dylib \"#{full_remote_path}\""
        $log.info "Checking if decrypted file #{decrypted_path} was created..."
      end

      if not $device.ops.file_exists? decrypted_path
        $log.error "Decryption failed. File may not be encrypted."
        return
      end

      $log.info "Decrypted file found. Downloading..."

      @local_decrypted_binary = "#{cache_dir}/#{File.basename full_remote_path}.decrypted"
      @binary.setDecryptedPath @local_decrypted_binary

      local_path = $device.ops.download decrypted_path, @local_decrypted_binary

      $log.info "Decrypted binary downloaded to #{@local_decrypted_binary}"
      @local_decrypted_binary

    end

    def get_raw_plist_value val
      begin
        @info_plist.plist_data[val]
      rescue
        "[error]"
      end
    end


    def find_icon
      # lets try the easy way first...
      icon_name = get_raw_plist_value('CFBundleIconFile')
      if not icon_name.nil?
        return icon_name
      end

      # lets try iphone icons
      icon_name = get_raw_plist_value('CFBundleIcons')
      unless icon_name.nil?
        if not icon_name["CFBundlePrimaryIcon"].nil? and not icon_name["CFBundlePrimaryIcon"]["CFBundleIconFiles"].nil?
          return icon_name["CFBundlePrimaryIcon"]["CFBundleIconFiles"].sort.last
        end
      end

      # lets try ipad icons
      icon_name = get_raw_plist_value('CFBundleIcons~ipad')
      unless icon_name.nil?
        if not icon_name["CFBundlePrimaryIcon"].nil? and not icon_name["CFBundlePrimaryIcon"]["CFBundleIconFiles"].nil?
          return icon_name["CFBundlePrimaryIcon"]["CFBundleIconFiles"].sort.last
        end
      end
    end

    def icon_path
      app_dir = Shellwords.escape(@app_dir)
      icon_name = find_icon

      unless (icon_name[-4,4] == ".png")
        $log.debug "Appending extension to #{icon_name}"
        icon_name += "*.png"
        $log.debug "Now: #{icon_name}"
      end

      icon_file = $device.ops.execute("ls #{app_dir}/*app/#{icon_name}").split("\n").first.strip

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
      get_raw_plist_value('CFBundleDisplayName').to_s
    end

    def keychain_access_groups
      if @keychain_access_groups.nil?
        "[iOS 8 specific]"
      else
        @keychain_access_groups.join "\n"
      end
    end

    def data_directory
      if $device.ios_version != 8
        "[iOS 8 specific]"
      else
        @data_dir
      end
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

    def undle_id
      begin
        @info_plist.bundle_identifier.to_s
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

    def sync_app_dir
      `#{rsync} avc -e ssh TKTK #{} `
    end

    def find_files_by_pattern pattern
      app_dir_files = $device.ops.dir_glob(@app_dir, pattern)
      data_dir_files = Array.new

      if app_dir != data_dir
        data_dir_files = $device.ops.dir_glob(@data_dir, pattern)
      end
      app_dir_files + data_dir_files
    end

    def find_plist_files
      $log.info "Looking for plist files..."
      find_files_by_pattern "**/*plist"
    end

    def find_sqlite_dbs
      $log.info "Looking for sqlite files..."
      find_files_by_pattern "**/*sql**"
    end

    def find_cache_dbs
      $log.info "Looking for Cache.db files..."
      find_files_by_pattern "**/Cache.db"
    end

    def get_url_handlers
      @info_plist.schemas
    end

    def cache_dir
     "#{$tmp_path}/#{@uuid}/"
    end


    def cache_file f
      relative_file = f.sub(@app_dir,'')
      relative_dir = File.dirname relative_file
      cache_dir = "#{$tmp_path}/#{@uuid}/#{relative_dir}"
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
      rescue Exception => ex
        $log.error "Error getting plist file #{info_plist_path}."
        $log.debug "Exception Details: #{ex.message}."
        $log.debug "Backtrace: #{ex.backtrace.join("\n")}."
        return
      end

      begin
        @info_plist = PlistUtil.new plist_file
        @info_plist.parse_info_plist
      rescue Exception => ex
        $log.error "Error parsing plist file #{plist_file}."
        $log.debug "Exception Details: #{ex.message}."
        $log.debug "Backtrace: #{ex.backtrace.join("\n")}."
        return
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
end
