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
    @app_dir = @sim_dir + "/Applications"
    @app = nil
    @ops = LocalOperations.new
  end




  def list_simulators
    basedir = ENV['HOME'] + '/Library/Application Support/iPhone Simulator'
    if not Dir.exists? basedir
      puts "No simulators found in #{basedir}."
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
      menu.header = "Multiple simulators found:"
      menu.prompt = "Choice:"

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
    su = ScreenShotUtil.new "#{@app_dir}/#{@app}", @ops, true

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
      puts "cert [install|uninstall|reinstall] certificate_file"
      return
    end

    case tokens[1]
      when "install", "reinstall", "uninstall"
        if tokens.length != 3
          puts "Syntax error."
          return
        end

        s = SimulatorCertificateInstaller.new @sim_dir
        s.send(tokens[1], tokens[2])
    end
  end


  def handle_app line
    tokens = line.split(' ')

    if tokens.length < 2
      puts "app [schemes|bundleid|name|select|info_plist]"
      return
    end

    case tokens[1]
      when "select"
        handle_select_app

      when "schemes"
        ensure_app_is_selected
        puts "Registered URL schemes for #{@app}:"
        h = HighLine.new
        puts h.list @plist.schemas

      when "bundleid"
        ensure_app_is_selected
        puts "Bundle identifier for #{@app}:"
        puts @plist.bundle_identifier

      when "name"
        ensure_app_is_selected
        puts "Bianry name for #{@app}:"
        puts @plist.binary_name

      when "info_plist"
        if tokens.length != 3
          puts "app info_plist [dump|print|open]"
          return
        end

        ensure_app_is_selected
        case tokens[2]
          when "dump"
            puts File.open(@plist.plist_file).read
          when "print"
            pp @plist.plist_data
          when "open"
            Launchy.open @plist.plist_file
        end
    end
  end

  def get_plist_file plist_file
    return plist_file
  end

  private

  def get_list_of_apps
    if not Dir.exists? @app_dir
      puts "Application directory #{@app_dir} not found."
      return false
    end

    dirs = Dir.glob("#{@app_dir}/**")
    if dirs.length == 0
      puts "No applications found in #{@app_dir}."
      return nil
    end
    return dirs
  end

  def get_appname_from_id id
    return File.basename Dir.glob("#{@app_dir}/#{id}/*app").first
  end


end