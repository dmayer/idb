require_relative 'abstract_device'
require_relative 'ssh_port_forwarder'
require_relative 'device_ca_interface'

class Device < AbstractDevice

  def initialize username, password, hostname, port
    @apps_dir = '/private/var/mobile/Applications'
    @username = username
    @password = password
    @hostname = hostname
    @port = port

    @app = nil
    @ops = SSHOperations.new username, password, hostname, port
    start_port_forwarding
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

  def simulator?
    false
  end

  def app_launch app
    @ops.launch_app(open_path, app.bundle_id)
  end


  def dumpdecrypted_installed?
    $log.info "Checking if dumpdecrypted is installed..."
    if not @ops.file_exists? "/var/root/dumpdecrypted.dylib"
      $log.info "dumpdecrypted not found. Installing..."
      false
    else
      $log.info "dumpdecrypted found."
      true
    end
  end

  def open_installed?
    puts "[*] Checking if open is installed..."
    if not @ops.file_exists? "/usr/bin/open"
      puts "[*] open not found."
      false
    else
      puts "[*] open found."
      true
    end
  end

  def open_path
    if @ops.file_exists? "/usr/bin/open"
      return "/usr/bin/open"
    end
  end

  def openurl_path
    if @ops.file_exists? "/usr/bin/openurl"
      return "/usr/bin/openurl"
    elsif  @ops.file_exists? "/usr/bin/openURL"
      return "/usr/bin/openURL"
    end
  end

  def openurl_installed?
    puts "[*] Checking if openurl is installed..."
    if @ops.file_exists? "/usr/bin/openurl" or  @ops.file_exists? "/usr/bin/openURL"
      return true
    else
      puts "[*] open not found. Installing..."
      false
    end
  end

  def apt_get_installed?
    puts "[*] Checking if apt-get is installed..."
    if not @ops.file_exists? "/usr/bin/apt-get"
      puts "[*] apt-get not found. Aboorting..."
      false
    else
      puts "[*] apt-get found."
      true
    end
  end

  def install_open
    if apt_get_installed?
      puts "[*] Installing open..."
      @ops.execute("/usr/bin/apt-get update")
      @ops.execute("/usr/bin/apt-get install com.conradkramer.open")
      return true
    else
      return false
    end
  end

  def close
    $log.info "Terminating port forwarding helper..."
   Process.kill("INT", @port_forward_pid)

  end


  def ca_interface
    DeviceCAInterface.new self
  end
end

