require_relative 'abstract_device'
require_relative 'ssh_port_forwarder'
require_relative 'device_ca_interface'
require_relative 'usb_muxd_wrapper'

class Device < AbstractDevice
  attr_accessor :usb_ssh_port, :mode, :tool_port

  def initialize username, password, hostname, port
    @apps_dir = '/private/var/mobile/Applications'
    @username = username
    @password = password
    @hostname = hostname
    @port = port

    @app = nil

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
      @ops = SSHOperations.new username, password, 'localhost', proxy_port

      @usb_ssh_port = $settings['manual_ssh_port']
      $log.debug "opening port #{proxy_port} for manual ssh connection"
      @usbmuxd.proxy @usb_ssh_port, $settings['ssh_port']

      @tool_port = @usbmuxd.find_available_port
      $log.debug "opening tool port #{@tool_port} for internal ssh connection"
      @usbmuxd.proxy @tool_port, $settings['ssh_port']

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

  def start_port_forwarding
    @port_forward_pid = Process.spawn("#{RbConfig.ruby} helper/ssh_port_forwarder.rb"  )
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
    local_path = "tmp/device/genp.plist"

    $log.info "Dumping keychain..."
    @ops.execute "#{keychain_dump_path}"
    $log.info "Downloading dumped keychain..."
    @ops.download device_store_path, local_path
  end


  def keychain_dump_path
    if @ops.file_exists? "/var/root/keychain_dump"
      "/var/root/keychain_dump"
    else
      nil
    end
  end

  def keychain_dump_installed?
    $log.info "checking if keychain_dump is installed..."
    if keychain_dump_path.nil?
      $log.warn "keychain_dump not found."
      false
    else
      $log.info "keychain_dump found."
      true
    end
  end

  def pcviewer_path
    if @ops.file_exists? "/var/root/protectionclassviewer"
      "/var/root/protectionclassviewer"
    else
      nil
    end
  end

  def pcviewer_installed?
    $log.info "checking if protectionclassviewer is installed..."
    if pcviewer_path.nil?
      $log.warn "protectionclassviewer not found."
      false
    else
      $log.info "protectionclassviewer found."
      true
    end
  end

  def pbwatcher_path
    if @ops.file_exists? "/var/root/pbwatcher"
      "/var/root/pbwatcher"
    else
      nil
    end
  end

  def pbwatcher_installed?
    $log.info "checking if pbwatcher is installed..."
    if pbwatcher_path.nil?
      $log.warn "pbwatcher not found."
      false
    else
      $log.info "pbwatcher found."
      true
    end
  end




  def dumpdecrypted_path
    if @ops.file_exists? "/var/root/dumpdecrypted.dylib"
      "/var/root/dumpdecrypted.dylib"
    else
      nil
    end
  end

  def dumpdecrypted_installed?
    $log.info "checking if dumpdecrypted is installed..."
    if dumpdecrypted_path.nil?
      $log.warn "dumpdecrypted not found."
      false
    else
      $log.info "dumpdecrypted found."
      true
    end
  end



  def open_installed?
    $log.info "Checking if open is installed..."
    if open_path.nil?
      $log.warn "open not found."
      false
    else
      $log.info "open found."
      true
    end
  end

  def open_path
    if @ops.file_exists? "/usr/bin/open"
      return "/usr/bin/open"
    else
      nil
    end
  end


  def openurl_path
    if @ops.file_exists? "/usr/bin/uiopen"
      return "/usr/bin/uiopen"
    elsif @ops.file_exists? "/usr/bin/openurl"
      return "/usr/bin/openurl"
    elsif  @ops.file_exists? "/usr/bin/openURL"
      return "/usr/bin/openURL"
    else
      nil
    end
  end

  def openurl_installed?
    $log.info "Checking if openurl is installed..."
    unless openurl_path.nil?
      true
    else
      $log.warn "openurl not found"
      false
    end
  end

  def apt_get_path
    if @ops.file_exists? "/usr/bin/apt-get"
      return "/usr/bin/apt-get"
    elsif @ops.file_exists? "/usr/bin/aptitude"
      return "/usr/bin/aptitude"
    else
      nil
    end

  end

  def apt_get_installed?
    $log.info "Checking if apt-get or aptitude is installed..."
    if apt_get_path.nil?
      $log.warn "apt-get or aptitude not found."
      false
    else
      $log.info "apt-get or aptitude found."
      true
    end
  end

  def install_dumpdecrypted
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


  def upload_dumpdecryted
    $log.info "Uploading dumpdecrypted library..."
    @ops.upload("utils/dumpdecrypted/dumpdecrypted.dylib","/var/root/dumpdecrypted.dylib")
    $log.info "'dumpdecrypted' installed successfully."
  end

  def install_keychain_dump
    if File.exist? "utils/keychain_dump/keychain_dump"
      upload_keychain_dump
    else
      $log.error "keychain_dump not found at 'utils/keychain_dump/keychain_dump'."
      false
    end
  end
  def install_pcviewer
    if File.exist? "utils/pcviewer/protectionclassviewer"
      upload_pcviewer
    else
      $log.error "protectionclassviewer not found at 'utils/pcviewer/protectionclassviewer'."
      false
    end
  end

  def install_pbwatcher
    if File.exist? "utils/pbwatcher/pbwatcher"
      upload_pbwatcher
    else
      $log.error "pbwatcher not found at 'utils/pbwatcher/pbwatcher'."
      false
    end
  end

  def upload_pcviewer
    begin
      $log.info "Uploading pcviewer..."
      @ops.upload "utils/pcviewer/protectionclassviewer", "/var/root/protectionclassviewer"
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
      @ops.upload "utils/keychain_dump/keychain_dump", "/var/root/keychain_dump"
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
      @ops.upload "utils/pbwatcher/pbwatcher", "/var/root/pbwatcher"
      @ops.chmod "/var/root/pbwatcher", 0744
      $log.info "'pbwatcher' installed successfully."
#      true
#    rescue
      $log.error "Exception encountered when uploading pbwatcher"
#      false
    end
  end

  def install_open
    if apt_get_installed?
      $log.info "Installing open..."
      @ops.execute("#{apt_get_path} -y update")
      @ops.execute("#{apt_get_path} -y install com.conradkramer.open")
      return true
    else
      return false
    end
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
    if $settings['devices'].nil?
      false
    elsif $settings['devices'][device_id].nil?
      false
    else
      true
    end
  end
end

