require 'highline/import'
require_relative 'simulator_certificate_installer'

class SimulatorIDB
  def initialize
    $sim_dir = list_simulators
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

  def handle_install line
    tokens = line.split(' ')

    if tokens.length < 2
      puts "Syntax error."
      return
    end

    case tokens[1]
      when "cert"
        if tokens.length != 3
          puts "Syntax error."
          return
        end
        install_certificate tokens[3]
    end
  end

  def install_certificate cert_file
    s = SimulatorCertificateInstaller.new $sim_dir
    s.install cert_file


  end


end