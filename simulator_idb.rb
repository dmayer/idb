require_relative 'common_idb'
require_relative 'local_operations'
def ensure_app_is_selected
  if @app.nil?
    if handle_select_app.nil?
      raise "Error retrieving list of apps."
    end
  end
end

class SimulatorIDB < CommonIDB

  def initialize
    @sim_dir = list_simulators
    @apps_dir = @sim_dir + "/Applications"
    @app = nil
    @ops = LocalOperations.new
  end

 def method_missing(name, *args, &block)
    puts "Method %s not implemented for the simulator." % name # name is a symbol
  end




  def list_simulators
    basedir = ENV['HOME'] + '/Library/Application Support/iPhone Simulator'
    unless Dir.exists? basedir
      puts 'No simulators found in #{basedir}.'
      exit 1
    end


    dirs = Dir.glob("#{basedir}/**")
    case dirs.length
      when 0
        puts "No simulators found in #{basedir}."
        exit 1
      when 1
        return dirs.first
    end

    choose do |menu|
      menu.header = 'Multiple simulators found:'
      menu.prompt = 'Choice:'

      dirs.each { |d|
        menu.choice(d) {
          say("[*] Using simulator in #{d}.")
          return d
        }
      }
    end
  end


  def handle_screen_shot line
    ensure_app_is_selected
    su = ScreenShotUtil.new "#{@apps_dir}/#{@app}", @ops, true

    ask "Launch the app in the simulator. [press enter to continue]"
    su.mark

    ask "Now place the app into the background. [press enter to continue]"

    result = su.check
    if result.nil?
      say "No screen shot found"
    else
      say "New screen shot found:"
      puts result
      a = agree "Do you want to view it? (y/n)"
      if a
        Launchy.open result
      end
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

  def handle_cert line
    tokens = line.split(' ')

    if tokens.length < 2
      puts "cert <action> certificate_file"
      puts "where <action> is one of:"
      puts "install    -  Installs a certificate in the trust store."
      puts "list       -  List all installed certificates in the trust store."
      puts "uninstall  -  Removes an existing certificate from the trust store."
      puts "reinstall  -  Removes and re-installs an existing certificate."
      return
    end

    case tokens[1]
      when "install", "reinstall", "uninstall"
        if tokens.length != 3
          puts "Syntax error. certificate_file not specified."
          return
        end

        s = SimulatorCertificateInstaller.new @sim_dir
        s.send(tokens[1], tokens[2])
      when 'list'
        s = SimulatorCertificateInstaller.new @sim_dir
        s.list
    end
  end


  def get_plist_file plist_file
    return plist_file
  end

  def handle_install
    puts "Install not available for the simulator."
  end

  private

  def app_launch
    ensure_app_is_selected
    cmd = '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone\ Simulator.app/Contents/MacOS/iPhone\ Simulator -SimulateApplication '
    puts "[*] Launching app..."
    @ops.launch_app cmd, path_to_app_binary
  end

  def get_list_of_apps
    if not Dir.exists? @apps_dir
      puts "Application directory #{@apps_dir} not found."
      return false
    end

    dirs = Dir.glob("#{@apps_dir}/**")
    if dirs.length == 0
      puts "No applications found in #{@apps_dir}."
      return nil
    end
    return dirs
  end

  def get_appname_from_id id
    return File.basename Dir.glob("#{@apps_dir}/#{id}/*app").first
  end


end
