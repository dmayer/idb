require 'fileutils'
require_relative 'common_idb'
require_relative 'ssh_operations'

class DeviceIDB < CommonIDB

  def initialize(username, password, hostname, port)
    @username = username
    @password = password
    @hostname = hostname
    @port = port

    @apps_dir = '/private/var/mobile/Applications'

    @app = nil
    @ops = SSHOperations.new username, password, hostname, port
  end


  def method_missing(name, *args, &block)
    puts "Method %s not implemented for a device." % name # name is a symbol
  end

  def handle_app line
    tokens = line.split(' ')

    if tokens.length < 2
      puts "app [list|select|download|decrypt]"
      return
    end

    case tokens[1]
      when "select"
        handle_select_app
      when "list"
        app_list
      when "download"
        app_download
      when "decrypt"
        app_decrypt
      when "url_handlers"
        app_url_handlers
      when "archive"
        app_archive
    end
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






  def handle_screen_shot line
    ensure_app_is_selected
    su = ScreenShotUtil.new "#{@apps_dir}/#{@app}", @ops, false

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

  def app_url_handlers
    ensure_app_is_selected
    puts "[*] Registered URL schemas based on Info.plist:"
    puts @plist.schemas
  end


  def app_archive
    ensure_app_is_selected
    puts "[*] Creating tar.gz of #{@app_dir}. This may take a while..."
    @ops.execute "/usr/bin/tar cfz /var/root/app_archive.tar.gz #{@app_dir}"

    local_path = "tmp/#{@app}/app_archive.tar.gz"

    puts "[*] Downloading app archive..."
    @ops.download "/var/root/app_archive.tar.gz", local_path

    puts "[*] App archive downloaded to #{local_path}."
  end

  def app_list
    dirs = get_list_of_apps
    apps = dirs.map { |x|
      id = File.basename x
      app_name = get_appname_from_id id
      "#{id} (#{app_name})"
    }

    h = HighLine.new
    puts h.list apps

  end

  def app_decrypt
    ensure_app_is_selected

    ensure_dumpdecrypted_is_installed

    full_remote_path = path_to_app_binary
    puts "[*] Running '#{full_remote_path}'"
    @ops.execute "cd /var/root/"
    @ops.execute "DYLD_INSERT_LIBRARIES=dumpdecrypted.dylib \"#{full_remote_path}\""

    decrypted_path = "/var/root/#{File.basename full_remote_path}.decrypted"
    puts "[*] Checking if decrypted file #{decrypted_path} was created..."
    if not @ops.file_exists? decrypted_path
      puts "[*] Decryption failed. File may not be encrypted. Try 'app download' instead."
      return
    end

    puts "[*] Decrypted file found. Downloading..."

    local_path = "tmp/#{@app}/#{@plist.binary_name}.app.decrypted"
    @ops.download decrypted_path, local_path

    puts "[*] Decrypted binary downloaded to #{local_path}"
  end

  def app_download
    ensure_app_is_selected

    full_remote_path = path_to_app_binary
    puts "[*] Downloading binary #{full_remote_path}"
    local_path = "tmp/#{@app}/#{@plist.binary_name}.app"
    @ops.download full_remote_path, local_path

    puts "[*] Binary downloaded to #{local_path}"
  end



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
    if not @ops.file_exists?  plist_file
      return nil
    end
    @ops.download plist_file, local_filename
    return local_filename
  end

  def get_list_of_apps
    if not @ops.file_exists? @apps_dir
      puts "Application directory #{@apps_dir} not found."
      return false
    end

    puts '[*] Retrieving list of applications...'

    dirs =  @ops.list_dir "#{@apps_dir}"
    dirs.select! { |x| x != "." and x != ".." }
    dirs.map! {|x| "#{@apps_dir}/#{x}"}

#    dirs = @ops.dir_glob("#{@apps_dir}/","**")
#    puts dirs
    if dirs.length == 0
      puts "No applications found in #{@apps_dir}."
      return nil
    end
    return dirs
  end

  def get_appname_from_id id
    return File.basename @ops.dir_glob("#{@apps_dir}/#{id}/","*app").first
  end

  def path_to_app_binary
    puts "[*] Locating application binary..."
    dirs = @ops.dir_glob("#{@app_dir}/","**")
    dirs.select! { |f|
      @ops.file_exists? "#{f}/#{@plist.binary_name}"
    }

    "#{dirs.first}/#{@plist.binary_name}"
  end


  def ensure_dumpdecrypted_is_installed
    puts "[*] Checking if dumpdecrypted is installed..."
    if not @ops.file_exists? "/var/root/dumpdecrypted.dylib"
      puts "[*] dumpdecrypted not found. Installing..."
      install_dumpdecrypted
    else
      puts "[*] dumpdecrypted found."
    end
  end



end
