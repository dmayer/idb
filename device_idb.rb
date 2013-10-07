require 'fileutils'
require_relative 'common_idb'
require_relative 'ssh_operations'

class DeviceIDB < CommonIDB

  def initialize(username, password, hostname, port)
    @username = username
    @password = password
    @hostname = hostname
    @port = port

    @app_dir = '/private/var/mobile/Applications'

    @app = nil
    @ops = SSHOperations.new username, password, hostname, port
  end

  def handle_app_download
    # download app binary.



  end

  def handle_app_decrypt
    # decrypt and download app binary


  end

  def handle_install line
    tokens = line.split(' ')

    if tokens.length < 2
      puts "install [killswitch|dumpdecrypted]"
      return
    end

    case tokens[1]
      when "killswitch"
        install_killswitch
      when "dumpdecrypted"
        install_dumpdecrypted
    end
  end

  def handle_list
    dirs = get_list_of_apps
    apps = dirs.map { |x|
      id = File.basename x
      app_name = get_appname_from_id id
      "#{id} (#{app_name})"
    }

    h = HighLine.new
    puts h.list apps

  end





  def handle_screen_shot line
    ensure_app_is_selected
    su = ScreenShotUtil.new "#{@app_dir}/#{@app}", @ops, false

    su.mark
    ask 'Launch the app on the device. [press enter to continue]'


    ask 'Now place the app into the background. [press enter to continue]'

    result = su.check
    if result.nil?
      say 'No screen shot found'
    else
      say 'New screen shot found:'
      puts result
      a = agree 'Do you want to download and view it? (y/n)'
      if a
        local_path = "tmp/#{@app}/#{File.basename result}"
        @ops.download result, local_path
        @ops.open local_path
      end
    end
  end

  private


  def install_killswitch
    puts "[*] Uploading Debian package..."
    @ops.upload("utils/ios-ssl-kill-switch/com.isecpartners.nabla.sslkillswitch_v0.5-iOS_6.1.deb","/var/root/com.isecpartners.nabla.sslkillswitch_v0.5-iOS_6.1.deb")
    puts "[*] Installing Debian package..."
    @ops.execute("/usr/bin/dpkg -i /var/root/com.isecpartners.nabla.sslkillswitch_v0.5-iOS_6.1.deb")
    puts "[*] Restarting SpringBoard..."
    @ops.execute("killall -HUP SpringBoard")
    puts "[*] iOS SSL Killswitch installed successfully."
    puts "[**] NOTE: If you need to intercept system applications you should reboot the device."
    a = agree 'Reboot now? (y/n)'
    if a
      puts "[*] Rebooting now. Please wait."
      @ops.execute("/sbin/reboot")
      puts "[*] idb exiting."
      exit
    end
  end


  def install_dumpdecrypted
    puts "[*] Uploading dumpdecrypted library..."
    @ops.upload("utils/dumpdecrypted/dumpdecrypted.dylib","/var/root/dumpdecrypted.dylib")
    puts "[*] 'dumpdecrypted' installed successfully."
  end


  def get_plist_file plist_file
    local_path = "tmp/#{@app}/"
    local_filename = "#{local_path}/Info.plist"
    FileUtils.mkdir_p local_path

    # the file is still remote. need to copy it for processing
    @ops.download plist_file, local_filename

    return local_filename
  end

  def get_list_of_apps
    if not @ops.file_exists? @app_dir
      puts "Application directory #{@app_dir} not found."
      return false
    end

    puts '[*] Retrieving list of applications...'

    dirs = @ops.dir_glob("#{@app_dir}/","**")
    if dirs.length == 0
      puts "No applications found in #{@app_dir}."
      return nil
    end
    return dirs
  end

  def get_appname_from_id id
    return File.basename @ops.dir_glob("#{@app_dir}/#{id}/","*app").first
  end


end
