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

        s = SimulatorCertificateInterface.new @sim_dir
        s.send(tokens[1], tokens[2])
      when 'list'
        s = SimulatorCertificateInterface.new @sim_dir
        s.list
    end
  end


  def get_plist_file plist_file
    return plist_file
  end

  def handle_install
    puts "Install not available for the simulator."
  end


  def app_launch app
    cmd = '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone\ Simulator.app/Contents/MacOS/iPhone\ Simulator -SimulateApplication '
    puts "[*] Launching app..."
    @ops.launch_app cmd, app.path_to_app_binary
  end




end
