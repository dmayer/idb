require 'highline/import'
require "highline/system_extensions"
require_relative 'simulator_certificate_installer'
require_relative 'screen_shot_util'
require 'launchy'

class SimulatorIDB
  def initialize
    @sim_dir = list_simulators
    @app_dir = @sim_dir + "/Applications"
    @app = nil
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
    su = ScreenShotUtil.new "#{@app_dir}/#{@app}"

    ask "Launch the app in the simulator. [press enter to continue]"

    su.sim_mark

    ask "Now place the app into the background. [press enter to continue]"

    result = su.sim_check
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


  def handle_select_app
    dirs = get_list_of_apps
    return nil if dirs.nil?

    choose do |menu|
      menu.header = "Select which application to use"
      menu.prompt = "Choice:"

      dirs.each { |d|
        id = File.basename d
        app_name = get_appname_from_id id
        menu.choice("#{id} (#{app_name})") {
          say("[*] Using application #{id}.")
          @app = id
        }
      }
    end
  end

  private

  def ensure_app_is_selected
    if @app.nil?
      if handle_select_app.nil?
        raise "Simulator or application installation appears broken."
      end
    end
  end

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