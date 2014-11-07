# encoding: utf-8

require_relative 'abstract_device'
require_relative 'ssh_port_forwarder'
require_relative 'device_ca_interface'
require_relative 'usb_muxd_wrapper'

module Idb
  class Device < AbstractDevice
    attr_accessor :usb_ssh_port, :mode, :tool_port, :ios_version

    def initialize username, password, hostname, port


      @username = username
      @password = password
      @hostname = hostname
      @port = port

      @app = nil

      @device_app_paths = Hash.new
      @device_app_paths[:cycript] = [ "/usr/bin/cycript" ]
      @device_app_paths[:rsync] = [ "/usr/bin/rsync" ]
      @device_app_paths[:open] = ["/usr/bin/open"]
      @device_app_paths[:openurl] = ["/usr/bin/uiopen", "/usr/bin/openurl",  "/usr/bin/openURL"]
      @device_app_paths[:aptget] = ["/usr/bin/apt-get",  "/usr/bin/aptitude"]
      @device_app_paths[:keychaindump] = [ "/var/root/keychain_dump"]
      @device_app_paths[:pcviewer] = ["/var/root/protectionclassviewer"]
      @device_app_paths[:pbwatcher] = ["/var/root/pbwatcher"]
      @device_app_paths[:dumpdecrypted_armv7] = ["/var/root/dumpdecrypted_armv7.dylib"]
      @device_app_paths[:dumpdecrypted_armv6] = ["/var/root/dumpdecrypted_armv6.dylib"]
      @device_app_paths[:clutch] = ["/usr/bin/Clutch"]

      if $settings['device_connection_mode'] == "ssh"
        $log.debug "Connecting via SSH"
        @mode = 'ssh'
        @ops = SSHOperations.new username, password, hostname, port
      else
        $log.debug "Connecting via USB"
        @mode = 'usb'
        @usbmuxd = USBMuxdWrapper.new
        proxy_port = @usbmuxd.find_available_port
        $log.debug "Using port #{proxy_port} for SSH forwarding"

        @usbmuxd.proxy proxy_port, $settings['ssh_port']
        sleep 1




        @ops = SSHOperations.new username, password, 'localhost', proxy_port

        @usb_ssh_port = $settings['manual_ssh_port']
        $log.debug "opening port #{proxy_port} for manual ssh connection"
        @usbmuxd.proxy @usb_ssh_port, $settings['ssh_port']

        @tool_port = @usbmuxd.find_available_port
        $log.debug "opening tool port #{@tool_port} for internal ssh connection"
        @usbmuxd.proxy @tool_port, $settings['ssh_port']

      end

      @apps_dir_ios_pre8 = '/private/var/mobile/Applications'
      @apps_dir_ios_8 = '/private/var/mobile/Containers/Bundle/Application'
      @data_dir_ios_8 = '/private/var/mobile/Containers/Data/Application'

      if @ops.directory? @apps_dir_ios_pre8
        @ios_version = 7 # 7 or earlier
        @apps_dir = @apps_dir_ios_pre8
        @data_dir = @apps_dir_ios_pre8

      elsif @ops.directory? @apps_dir_ios_8
        @ios_version = 8
        @apps_dir = @apps_dir_ios_8
        @data_dir = @data_dir_ios_8

      else
        $log.error "Unsupported iOS Version."
        raise
      end

      start_port_forwarding
    end

    def ssh
      @ops.ssh
    end


    def disconnect
      @ops.disconnect
    end

    def device?
      true
    end

    def arch
      "armv7"
    end

    def start_port_forwarding
      @port_forward_pid = Process.spawn("#{RbConfig.ruby} #{File.dirname(File.expand_path(__FILE__))}/../helper/ssh_port_forwarder.rb"  )
    end

    def restart_port_forwarding
      $log.info "Restarting SSH port forwarding"
      Process.kill("INT", @port_forward_pid)
      start_port_forwarding
    end

    def protection_class file
      @ops.execute "#{pcviewer_path} '#{file}'"
    end

    def simulator?
      false
    end

    def app_launch app
      @ops.launch_app(open_path, app.bundle_id)
    end


    def dump_keychain
      device_store_path = "/var/root/genp.plist"
      local_dir = "#{$tmp_path}/device/"
      local_path = "#{local_dir}/genp.plist"
      FileUtils.mkdir_p local_dir unless Dir.exist? local_dir

      $log.info "Dumping keychain..."
      @ops.execute "#{keychain_dump_path}"
      $log.info "Downloading dumped keychain..."
      @ops.download device_store_path, local_path
    end




    def is_installed? tool
      $log.info "Checking if #{tool} is installed..."
      if path_for(tool).nil?
        $log.warn "#{tool} not found."
        false
      else
        $log.info "#{tool} found at #{path_for(tool)}."
        true
      end
    end

    def path_for tool
      @device_app_paths[tool].each { |x|
        if @ops.file_exists? x
          return x
        end
      }
      return nil
    end


    def install_dumpdecrypted
      upload_dumpdecrypted
    end

    def install_dumpdecrypted_old
      unless File.exist? "utils/dumpdecrypted/dumpdecrypted.dylib"
        puts "[**] Warning: dumpdecrypted not compiled."
        puts "[**] Due to licensing issue we cannot ship the compiled library with this tool."
        puts "[**] Attempting compilation (requires a valid iOS SDK installation)..."
        compile_dumpdecrypted

        if File.exist? "utils/dumpdecrypted/dumpdecrypted.dylib"
          puts "[**] Compilation successful."
          upload_dumpdecryted
        else
          puts "[**] Error: Compilation failed."
          puts "[**] Change into the utils/dumpdecrypted directory, adjust the makefile, and compile."
        end
      else
        upload_dumpdecryted
      end
    end


    def compile_dumpdecrypted
      base_dir = '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer'
      unless Dir.exist? base_dir
        puts "[**] Error, iOS Platform tools not found at #{base_dir}"
        return
      end


      bin_dir = "#{base_dir}/usr/bin"
      sdk_dir = Dir.glob("#{base_dir}/SDKs/iPhoneOS*.sdk/").first
      puts "[*] Found SDK dir: #{sdk_dir}"

      library_name = "dumpdecrypted.dylib"
      gcc = "#{bin_dir}/gcc"

      unless File.exist? gcc
        puts "[**] Error: gcc not found at #{gcc}"
        puts "[**] Ensure that the Command Line Utilities are installed in XCode 4."
        puts "[**] XCode 5 does not ship with llvm-gcc anymore."
        return
      end



      params = ["-arch armv7", # adjust if necessary
                "-wimplicit",
                "-isysroot #{sdk_dir}",
                "-F#{sdk_dir}System/Library/Frameworks",
                "-F#{sdk_dir}System/Library/PrivateFrameworks",
                "-dynamiclib",
                "-o #{library_name}"].join(' ')

      compile_cmd = "#{gcc} #{params} dumpdecrypted.c"
      puts "Running #{compile_cmd}"

      Dir.chdir("utils/dumpdecrypted") do
        `#{compile_cmd}`
      end
    end


    def upload_dumpdecrypted
      $log.info "Uploading dumpdecrypted library..."
      @ops.upload("#{File.dirname(File.expand_path(__FILE__))}/../utils/dumpdecrypted/dumpdecrypted_armv6.dylib","/var/root/dumpdecrypted_armv6.dylib")
      @ops.upload("#{File.dirname(File.expand_path(__FILE__))}/../utils/dumpdecrypted/dumpdecrypted_armv7.dylib","/var/root/dumpdecrypted_armv7.dylib")
      $log.info "'dumpdecrypted' installed successfully."
    end

    def install_keychain_dump
      if File.exist? "#{File.dirname(File.expand_path(__FILE__))}/../utils/keychain_dump/keychain_dump"
        upload_keychain_dump
      else
        $log.error "keychain_dump not found at '#{File.dirname(File.expand_path(__FILE__))}/../utils/keychain_dump/keychain_dump'."
        false
      end
    end
    def install_pcviewer
      if File.exist? "#{File.dirname(File.expand_path(__FILE__))}/../utils/pcviewer/protectionclassviewer"
        upload_pcviewer
      else
        $log.error "protectionclassviewer not found at '#{File.dirname(File.expand_path(__FILE__))}/../utils/pcviewer/protectionclassviewer'."
        false
      end
    end


    def install_pbwatcher
      if File.exist? "#{File.dirname(File.expand_path(__FILE__))}/../utils/pbwatcher/pbwatcher"
        upload_pbwatcher
      else
        $log.error "pbwatcher not found at '#{File.dirname(File.expand_path(__FILE__))}/../utils/pbwatcher/pbwatcher'."
        false
      end
    end

    def upload_pcviewer
      begin
        $log.info "Uploading pcviewer..."
        @ops.upload "#{File.dirname(File.expand_path(__FILE__))}/../utils/pcviewer/protectionclassviewer", "/var/root/protectionclassviewer"
        @ops.chmod "/var/root/protectionclassviewer", 0744
        $log.info "'pcviewer' installed successfully."
  #      true
  #    rescue
        $log.error "Exception encountered when uploading pcviewer"
  #      false
      end
    end

    def upload_keychain_dump
      begin
        $log.info "Uploading keychain_dump..."
        @ops.upload "#{File.dirname(File.expand_path(__FILE__))}/../utils/keychain_dump/keychain_dump", "/var/root/keychain_dump"
        @ops.chmod "/var/root/keychain_dump", 0744
        $log.info "'keychain_dump' installed successfully."
  #      true
  #    rescue
        $log.error "Exception encountered when uploading keychain_dump"
  #      false
      end
    end
    def upload_pbwatcher
      begin
        $log.info "Uploading pbwatcher..."
        @ops.upload "#{File.dirname(File.expand_path(__FILE__))}/../utils/pbwatcher/pbwatcher", "/var/root/pbwatcher"
        @ops.chmod "/var/root/pbwatcher", 0744
        $log.info "'pbwatcher' installed successfully."
  #      true
  #    rescue
        $log.error "Exception encountered when uploading pbwatcher"
  #      false
      end
    end

    def setup_clutch_sources
      @ops.execute("echo “deb http://cydia.iphonecake.com ./“ > /etc/apt/sources.list.d/idb_clutch.list")
    end

    def install_from_cydia package
      if apt_get_installed?
        $log.info "Updating package repo..."
        @ops.execute("#{apt_get_path} -y update")
        $log.info "Installing #{package}..."
        @ops.execute("#{apt_get_path} -y install #{package}")
        return true
      else
        $log.error "apt-get or aptitude not found on the device"
        return false
      end
    end

    def install_open
      install_from_cydia "com.conradkramer.open"
    end

    def install_clutch
      install_from_cydia "com.iphonecake.clutch"
    end

    def install_rsync
      install_from_cydia "rsync"
    end

    def install_cycript
      install_from_cydia "cycript"
    end

    def close
      $log.info "Terminating port forwarding helper..."
      Process.kill("INT", @port_forward_pid)
      $log.info "Stopping any SSH via USB forwarding"
      @usbmuxd.stop_all
    end

    def open_url url
      $log.info "Executing: #{openurl_path} #{url}"
      @ops.execute "#{openurl_path} #{url}"
    end

    def ca_interface
      DeviceCAInterface.new self
    end

    def kill_by_name process_name
      @ops.execute "killall -9 #{process_name}"
    end

    def device_id

      $log.error "Not implemented"
      nil
    end

    def configured?
      apt_get_installed? and open_installed? and openurl_installed? and dumpdecrypted_installed? and pbwatcher_installed? and pcviewer_installed? and keychain_dump_installed? and rsync_installed? and cycript_installed?
    end


    def cycript_installed?
      is_installed? :cycript
    end

    def keychain_dump_installed?
      is_installed? :keychaindump
    end

    def pcviewer_installed?
      is_installed? :pcviewer
    end

    def pbwatcher_installed?
      is_installed? :pbwatcher
    end

    def dumpdecrypted_installed?
      is_installed? :dumpdecrypted_armv6 and is_installed? :dumpdecrypted_armv7
    end


    def rsync_installed?
      is_installed? :rsync
    end

    def open_installed?
      is_installed? :open
    end

    def openurl_installed?
      is_installed? :openurl
    end

    def apt_get_installed?
      is_installed? :aptget
    end

    def clutch_installed?
      is_installed? :clutch
    end

    def keychain_dump_path
      path_for :keychaindump
    end



    def pcviewer_path
      path_for  :pcviewer
    end


    def pbwatcher_path
      path_for :pbwatcher
    end


    def dumpdecrypted_path
      path_for :dumpdecrypted_armv7
    end

    def rsync_path
      path_for :rsync
    end


    def open_path
      path_for :open
    end


    def openurl_path
      path_for :openurl
    end


    def apt_get_path
      path_for :aptget
    end

    def clutch_path
      path_for :clutch
    end

    def cycript_path
      path_for :cycript
    end

  end
end
