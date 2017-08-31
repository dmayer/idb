require_relative 'plist_util'
require_relative 'app_binary'
require_relative 'CgBI'
require_relative 'ios8_last_launch_services_map_wrapper'
require_relative 'ios10_application_state_db_wrapper'

module Idb
  class App
    attr_accessor :uuid, :app_dir, :binary, :cache_dir, :services_map
    attr_reader :data_dir

    def initialize(uuid)
      @uuid = uuid
      @cache_dir = "#{$tmp_path}/#{uuid}"
      FileUtils.mkdir_p @cache_dir  unless Dir.exist? @cache_dir


      @app_dir = "#{$device.apps_dir}/#{@uuid}"
      $log.debug "App Dir: #{@app_dir}"

      parse_info_plist


      if $device.ios_version >= 10
        @services_map = IOS10ApplicationStateDbWrapper.new
        @data_dir = @services_map.data_path_by_bundle_id @info_plist.bundle_identifier

      elsif $device.ios_version >= 8
        if $device.ios_version == 8
          mapping_file = "/var/mobile/Library/MobileInstallation/LastLaunchServicesMap.plist"
        else
          mapping_file = "/private/var/installd/Library/MobileInstallation/LastLaunchServicesMap.plist"
        end

        local_mapping_file = cache_file mapping_file
        @services_map = IOS8LastLaunchServicesMapWrapper.new local_mapping_file
        @data_dir = @services_map.data_path_by_bundle_id @info_plist.bundle_identifier

      else
        @data_dir = @app_dir
      end
#      binding.pry
      $log.debug "Data Dir: #{@data_dir}"
    end


    def analyze
      local_binary_path = cache_file binary_path
      @binary = AppBinary.new local_binary_path
      if @binary.encrypted?
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
      $log.info "Running '#{binary_path}'"
      full_remote_path = binary_path
      $log.error "Decryption failed. Trying using dumpdecrypted..."

      unless $device.dumpdecrypted_installed?
        $log.error "dumpdecrypted not installed."
        return false
      end

      dylib_path = $device.path_for("dumpdecrypted_#{$device.arch}".to_sym)

      # If the ios version is less than 9 then we execute dumpdecrypted as
      # root. iOS 9 requires dumpdecrypted to be run as the mobile user.
      if $device.ios_version < 9
        # TODO: Is this the best way to do this?
        decrypted_path = "/var/root/#{File.basename full_remote_path}.decrypted"
        $device.ops.execute "DYLD_INSERT_LIBRARIES=#{dylib_path} \"#{full_remote_path}\""
      else
        # TODO: Is this the best way to do this?
        decrypted_path = "/var/mobile/#{File.basename full_remote_path}.decrypted"
        $device.ops.execute "DYLD_INSERT_LIBRARIES=#{dylib_path} \"#{full_remote_path}\"", as_user: "mobile"
      end

      $log.info "Checking if decrypted file #{decrypted_path} was created..."
      unless $device.ops.file_exists? decrypted_path
        $log.error "Decryption failed. Trying armv6 build for iOS 6 and earlier..."
        $device.ops.execute "DYLD_INSERT_LIBRARIES=dumpdecrypted_armv6.dylib \"#{full_remote_path}\""
        $log.info "Checking if decrypted file #{decrypted_path} was created..."
      end

      unless $device.ops.file_exists? decrypted_path
        $log.error "Decryption failed. File may not be encrypted."
        return
      end

      $log.info "Decrypted file found. Downloading..."

      @local_decrypted_binary = "#{cache_dir}/#{File.basename full_remote_path}.decrypted"
      @binary.decrypted_path = @local_decrypted_binary

      local_path = $device.ops.download decrypted_path, @local_decrypted_binary

      $log.info "Decrypted binary downloaded to #{@local_decrypted_binary}"
      @local_decrypted_binary
    end

    def get_raw_plist_value(val)
      @info_plist.plist_data[val]
    rescue
      "[error]"
    end

    def find_icon
      # lets try the easy way first...
      icon_name = get_raw_plist_value('CFBundleIconFile')
      return icon_name unless icon_name.nil?

      # lets try iphone icons
      icon_name = get_raw_plist_value('CFBundleIcons')
      unless icon_name.nil?
        if !icon_name["CFBundlePrimaryIcon"].nil? && !icon_name["CFBundlePrimaryIcon"]["CFBundleIconFiles"].nil?
          return icon_name["CFBundlePrimaryIcon"]["CFBundleIconFiles"].sort.last
        end
      end

      # lets try ipad icons
      icon_name = get_raw_plist_value('CFBundleIcons~ipad')
      unless icon_name.nil?
        if !icon_name["CFBundlePrimaryIcon"].nil? && !icon_name["CFBundlePrimaryIcon"]["CFBundleIconFiles"].nil?
          return icon_name["CFBundlePrimaryIcon"]["CFBundleIconFiles"].sort.last
        end
      end
    end

    def icon_path
      app_dir = Shellwords.escape(@app_dir)
      icon_name = find_icon

      unless icon_name[-4, 4] == ".png"
        $log.debug "Appending extension to #{icon_name}"
        icon_name += "*.png"
        $log.debug "Now: #{icon_name}"
      end

      icon_file = $device.ops.execute("ls #{app_dir}/*app/#{icon_name}").split("\n").first.strip

      unless $device.ops.file_exists? icon_file
        $log.warn "Icon not found: #{icon_file}"
        return nil
      end
      $log.info "Icon found at #{icon_file}"
      icon_file
    end

    def get_icon_file
      path = icon_path

      unless path.nil?
        local_path = cache_file path
        new_local_path = "#{local_path}.png"
        CGBI.from_file(local_path).to_png_file(new_local_path)
        new_local_path
      end
    end

    def bundle_name
      get_raw_plist_value('CFBundleDisplayName').to_s
    end

    def keychain_access_groups
      if $device.ios_version < 8
        "[iOS 8+ specific]"
      end

      ## return stored groups if we have them
      unless @keychain_access_groups.nil?
       return @keychain_access_groups.join ("\n")
      end

      if $device.ios_version >= 10
        @keychain_access_groups = @services_map.keychain_access_groups_by_binary binary_path
      end

      if $device.ios_version >= 8
        @keychain_access_groups = @services_map.keychain_access_groups_by_bundle_id @info_plist.bundle_identifier
      end

      @keychain_access_groups.join ("\n")
    end

    def data_directory
      if $device.ios_version < 8
        "[iOS 8+ specific]"
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

    def bundle_id
      @info_plist.bundle_identifier.to_s
    rescue
      "[error]"
    end

    def launch
      $device.app_launch self
    end

    def binary_path
      if @binary_path.nil?
        $log.info "Locating application binary..."
        dirs = $device.ops.dir_glob("#{@app_dir}/", "**")
        dirs.select! do |f|
          $device.ops.file_exists? "#{f}/#{binary_name}"
        end

        @binary_path = "#{dirs.first}/#{binary_name}"
      else
        @binary_path
      end

    end

    def binary_name
      @info_plist.binary_name
    rescue
      "[error]"
    end

    def sync_app_dir
      `#{rsync} avc -e ssh TKTK #{}`
    end

    def find_files_by_pattern(pattern)
      app_dir_files = $device.ops.dir_glob(@app_dir, pattern)
      data_dir_files = []

      if @app_dir != @data_dir
        puts "IN DATA DIR: #{@data_dir}"
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

    def cache_file(f)
      relative_file = f.sub(@app_dir, '')
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


    def entitlements
      if $device.ios_version >= 10
        @services_map.entitlements_by_binary(binary_path)
      elsif $device.ios_version >= 8
        @services_map.entitlements_by_bundle_id(bundle_id)
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
      # plist_file = (@if.ops.dir_glob "#{@app_dir}/","*app/Info.plist").first

      unless $device.ops.file_exists? plist_file
        $log.error "Info.plist not found."
        return nil
      end
      $log.info "Info.plist found at #{plist_file}"
      plist_file
    end

  end
end
