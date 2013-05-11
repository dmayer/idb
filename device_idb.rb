require 'fileutils'
require_relative 'common_idb'
require_relative 'ssh_operations'

class DeviceIDB < CommonIDB

  def initialize username, password, hostname, port
    @username = username
    @password = password
    @hostname = hostname
    @port = port

    @app_dir ="/private/var/mobile/Applications"

    @app = nil
    @ops = SSHOperations.new username, password, hostname, port
  end





  def handle_screen_shot line
    ensure_app_is_selected
    su = ScreenShotUtil.new "#{@app_dir}/#{@app}", @ops, false

    ask "Launch the app on the device. [press enter to continue]"
    su.mark

    ask "Now place the app into the background. [press enter to continue]"

    result = su.check
    if result.nil?
      say "No screen shot found"
    else
      say "New screen shot found:"
      puts result
      a = agree "Do you want to download and view it? (y/n)"
      if a
        @ops.open result
      end
    end
  end

  private


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