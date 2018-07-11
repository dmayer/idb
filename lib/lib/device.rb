# encoding: utf-8

require_relative 'abstract_device'
require_relative 'ssh_port_forwarder'
require_relative 'device_ca_interface'
require_relative 'usb_muxd_wrapper'
require 'json'

module Idb
  class Device < AbstractDevice
    attr_accessor :usb_ssh_port, :mode, :tool_port, :ios_version
    attr_reader :data_dir

    def initialize(username, password, hostname, port)
      @username = username
      @password = password
      @hostname = hostname
      @port = port

      @app = nil

      @device_app_paths = {}
      @device_app_paths[:cycript] = ["/usr/bin/cycript"]
      @device_app_paths[:rsync] = ["/usr/bin/rsync"]
      @device_app_paths[:open] = ["/usr/bin/open"]
      @device_app_paths[:openurl] = ["/usr/bin/uiopen",
                                     "/usr/bin/openurl",
                                     "/usr/bin/openURL"]
      @device_app_paths[:aptget] = ["/usr/bin/apt-get", "/usr/bin/aptitude"]
      @device_app_paths[:keychaineditor] = ["/var/root/keychaineditor"]
      @device_app_paths[:pcviewer] = ["/var/root/protectionclassviewer"]
      @device_app_paths[:pbwatcher] = ["/var/root/pbwatcher"]
      @device_app_paths[:dumpdecrypted_armv7] = ["/usr/lib/dumpdecrypted_armv7.dylib"]
      @device_app_paths[:dumpdecrypted_armv6] = ["/usr/lib/dumpdecrypted_armv6.dylib"]

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

      @apps_dir_ios_9 = '/private/var/containers/Bundle/Application'
      @data_dir_ios_9 = @data_dir_ios_8
      @application_state_ios_10 = "/User/Library/FrontBoard/applicationState.db"

      $log.info "Checking iOS version"

      @ops.execute"touch /tmp/daniel"

      str_ios_version = @ops.execute("sw_vers | grep ProductVersion | cut -d' ' -f2 | cut -d'.' -f1")
      str_ios_version = str_ios_version.gsub!(/[\s\n]+/, "")
      @ios_version = str_ios_version.to_i

      # failover in case the sw_vers method fails to return a valid major version
      if @ios_version.to_s != str_ios_version

        # this check is buggy: FrontBoard found in 9.3.3
        # FIXME: would removing the FrontBoard check cause problems later?
        #        e.g. assuming version 9 or later (and setting up ios_version = 9)
        #        when @apps_dir_ios_9 dir exists
        if @ops.file_exists? @application_state_ios_10
          @ios_version = 10

        elsif @ops.directory? @apps_dir_ios_9
          @ios_version = 9

        elsif @ops.directory? @apps_dir_ios_8
          @ios_version = 8

        elsif @ops.directory? @apps_dir_ios_pre8
          @ios_version = 7 # 7 or earlier

        else
          $log.error "Unsupported iOS Version."
          raise
        end
      end

      if @ios_version >= 10
        $log.info "iOS Version: 10 or newer"
        @apps_dir = @apps_dir_ios_9
        @data_dir = @data_dir_ios_9

      elsif @ios_version == 9
        $log.info "iOS Version: 9"
        @apps_dir = @apps_dir_ios_9
        @data_dir = @data_dir_ios_9

      elsif @ios_version == 8
        $log.info "iOS Version: 8"
        @apps_dir = @apps_dir_ios_8
        @data_dir = @data_dir_ios_8

      else
        $log.info "iOS Version: 7 or earlier"
        @apps_dir = @apps_dir_ios_pre8
        @data_dir = @apps_dir_ios_pre8
      end
      $log.info "iOS Version: #{@ios_version} with apps dir: #{@apps_dir} and data dir: #{@data_dir}"

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
      command = "#{RbConfig.ruby} #{Idb.root}/lib/helper/ssh_port_forwarder.rb"
      @port_forward_pid = Process.spawn(command)
    end

    def restart_port_forwarding
      $log.info "Restarting SSH port forwarding"
      Process.kill("INT", @port_forward_pid)
      start_port_forwarding
    end

    def protection_class(file)
      @ops.execute "#{pcviewer_path} '#{file}'"
    end

    def simulator?
      false
    end

    def app_launch(app)
      @ops.launch_app(open_path, app.bundle_id)
    end

    def is_installed?(tool)
      $log.info "Checking if #{tool} is installed..."
      if path_for(tool).nil?
        $log.warn "#{tool} not found."
        false
      else
        $log.info "#{tool} found at #{path_for(tool)}."
        true
      end
    end

    def path_for(tool)
      @device_app_paths[tool].each do |device_app_path|
        return device_app_path if @ops.file_exists? device_app_path
      end
      nil
    end

    def install_dumpdecrypted
      upload_dumpdecrypted
      # Change permissions as this needs to be run as the mobile user
      @ops.chmod dumpdecrypted_path, 0755
      @ops.chmod dumpdecrypted_path_armv6, 0755
    end

    def upload_dumpdecrypted
      $log.info "Uploading dumpdecrypted library..."
      @ops.upload("#{Idb.root}/lib/utils/dumpdecrypted/dumpdecrypted_armv6.dylib",
                  @device_app_paths[:dumpdecrypted_armv6].first)
      @ops.upload("#{Idb.root}/lib/utils/dumpdecrypted/dumpdecrypted_armv7.dylib",
                  @device_app_paths[:dumpdecrypted_armv7].first)
      $log.info "'dumpdecrypted' installed successfully."
    end

    def install_keychain_editor
      keychaineditor_path = "#{Idb.root}/lib/utils/keychain_editor/keychaineditor"
      if File.exist? keychaineditor_path
        upload_keychain_editor
      else
        $log.error "keychain_editor not found at '#{keychaineditor_path}'."
        false
      end
    end

    def install_pcviewer
      pcviewer_path = "#{Idb.root}/lib/utils/pcviewer/protectionclassviewer"
      if File.exist? pcviewer_path
        upload_pcviewer
      else
        $log.error "protectionclassviewer not found at '#{pcviewer_path}'."
        false
      end
    end

    def install_pbwatcher
      pbwatcher_path = "#{Idb.root}/lib/utils/pbwatcher/pbwatcher"
      if File.exist? pbwatcher_path
        upload_pbwatcher
      else
        $log.error "pbwatcher not found at '#{pbwatcher_path}'."
        false
      end
    end

    def upload_pcviewer
      local_pcviewer_path = "#{Idb.root}/lib/utils/pcviewer/protectionclassviewer"
      $log.info "Uploading pcviewer..."
      @ops.upload local_pcviewer_path, "/var/root/protectionclassviewer"
      @ops.chmod "/var/root/protectionclassviewer", 0744
      $log.info "'pcviewer' installed successfully."
    end

    def upload_keychain_editor
      local_keychaineditor_path = "#{Idb.root}/lib/utils/keychain_editor/keychaineditor"
      $log.info "Uploading keychain_editor..."
      @ops.upload local_keychaineditor_path, "/var/root/keychaineditor"
      @ops.chmod "/var/root/keychaineditor", 0744
      $log.info "'keychain_editor' installed successfully."
    end

    def upload_pbwatcher
      local_pbwatcher_path = "#{Idb.root}/lib/utils/pbwatcher/pbwatcher"
      $log.info "Uploading pbwatcher..."
      @ops.upload local_pbwatcher_path, "/var/root/pbwatcher"
      @ops.chmod "/var/root/pbwatcher", 0744
      $log.info "'pbwatcher' installed successfully."
    end

    def install_from_cydia(package)
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

      @usbmuxd.stop_all if $settings['device_connection_mode'] != "ssh"
    end

    def open_url(url)
      command = "#{openurl_path} \"#{url.gsub('&', '\&')}\""
      $log.info "Executing: #{command}"
      @ops.execute  command
    end

    def ca_interface
      DeviceCAInterface.new self
    end

    def kill_by_name(process_name)
      @ops.execute "killall -9 #{process_name}"
    end

    def device_id
      $log.error "Not implemented"
      nil
    end

    def configured?
      apt_get_installed? &&
        open_installed? &&
        openurl_installed? &&
        dumpdecrypted_installed? &&
        pbwatcher_installed? &&
        pcviewer_installed? &&
        keychain_editor_installed? &&
        rsync_installed? &&
        cycript_installed?
    end

    def cycript_installed?
      is_installed? :cycript
    end

    def keychain_editor_installed?
      is_installed? :keychaineditor
    end

    def pcviewer_installed?
      is_installed? :pcviewer
    end

    def pbwatcher_installed?
      is_installed? :pbwatcher
    end

    def dumpdecrypted_installed?
      is_installed?(:dumpdecrypted_armv6) && is_installed?(:dumpdecrypted_armv7)
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

    def keychain_editor_path
      path_for :keychaineditor
    end

    def pcviewer_path
      path_for :pcviewer
    end

    def pbwatcher_path
      path_for :pbwatcher
    end

    def dumpdecrypted_path
      path_for :dumpdecrypted_armv7
    end

    def dumpdecrypted_path_armv6
      path_for :dumpdecrypted_armv6
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

    def cycript_path
      path_for :cycript
    end
  end
end
