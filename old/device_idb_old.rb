require 'fileutils'
require_relative 'common_idb'
require_relative 'ssh_operations'

class DeviceIDB < CommonIDB
  attr_accessor :ops, :apps_dir



  def method_missing(name, *args, &block)
    puts "Method %s not implemented for a device." % name # name is a symbol
  end


  def handle_install line
    tokens = line.split(' ')

    if tokens.length < 2
      puts "install [killswitch|dumpdecrypted|open]"
      return
    end

    case tokens[1]
      when "killswitch"
        install_killswitch
      when "dumpdecrypted"
        install_dumpdecrypted
      when "open"
        install_open
    end
  end






  def handle_screen_shot line
    ensure_app_is_selected
    su = ScreenShotUtil.new "#{@apps_dir}/#{@app}", @ops, false

    su.mark
    ask 'Launch the app on the device. [press enter to continue]'


    ask 'Now place the app into the background (hit the home button). [press enter to continue]'

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


  def app_launch app
    if ensure_open_is_installed
      cmd = 'open'
      puts "[*] Launching app..."
      @ops.launch_app cmd, app.bundle_id
    end
  end

  def app_archive
    ensure_app_is_selected
    puts "[*] Creating tar.gz of #{@app_dir}. This may take a while..."
    @ops.execute "/usr/bin/tar cfz /var/root/app_archive.tar.gz \"#{@app_dir}\""

    local_path = "tmp/#{@app}/app_archive.tar.gz"

    puts "[*] Downloading app archive..."
    @ops.download "/var/root/app_archive.tar.gz", local_path

    puts "[*] App archive downloaded to #{local_path}."
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
    puts "[*] Uploading dumpdecrypted library..."
    @ops.upload("utils/dumpdecrypted/dumpdecrypted.dylib","/var/root/dumpdecrypted.dylib")
    puts "[*] 'dumpdecrypted' installed successfully."
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


  def get_file file
    local_path = "tmp/#{@app}/#{File.basename file}"
    local_filename = "#{local_path}/Info.plist"
    FileUtils.mkdir_p local_path

    # the file is still remote. need to copy it for processing
    if not @ops.file_exists?  plist_file
      return nil
    end
    @ops.download plist_file, local_filename
    return local_filename
  end


  def get_appname_from_id id
    begin
      return File.basename @ops.dir_glob("#{@apps_dir}/#{id}/","*app").first
    rescue
      return "Could not determine app name"
      end
  end


end
