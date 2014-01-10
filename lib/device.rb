require_relative 'abstract_device'
require_relative 'ssh_port_forwarder'
require_relative 'device_ca_interface'
require_relative 'usb_muxd_wrapper'

class Device < AbstractDevice
  attr_accessor :usb_ssh_port, :mode

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
      $log.debug "Opening port #{proxy_port} for manual SSH connection"
      @usbmuxd.proxy @usb_ssh_port, $settings['ssh_port']

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

  def simulator?
    false
  end

  def app_launch app
    @ops.launch_app(open_path, app.bundle_id)
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

  def upload_dumpdecryted
    $log.info "Uploading dumpdecrypted library..."
    @ops.upload("utils/dumpdecrypted/dumpdecrypted.dylib","/var/root/dumpdecrypted.dylib")
    $log.info "'dumpdecrypted' installed successfully."
  end


  def install_pbwatcher
    if File.exist? "utils/pbwatcher/pbwatcher"
      upload_pbwatcher
    else
      $log.error "pbwatcher not found at 'utils/pbwatcher/pbwatcher'."
      false
    end
  end


  def upload_pbwatcher
    begin
      $log.info "Uploading pbwatcher..."
      @ops.upload "utils/pbwatcher/pbwatcher", "/var/root/pbwatcher"
      $log.info "'pbwatcher' installed successfully."
      true
    rescue
      $log.error "Exception encountered when uploading pbwatcher"
      false
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

