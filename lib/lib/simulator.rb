require_relative 'abstract_device'
require_relative 'simulator_ca_interface'
require_relative 'local_operations'

module Idb
  class Simulator < AbstractDevice
    attr_accessor :sim_dir

    def initialize(sim_dir)
      puts "Initializing simulator with #{sim_dir}"
      @sim_dir = sim_dir
      @apps_dir = @sim_dir + "/Applications"
      @ops = LocalOperations.new
    end

    def open_installed?
      true
    end

    def app_launch(app)
      cmd = '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/' \
            'Developer/Applications/iPhone\ Simulator.app/Contents/MacOS/' \
            'iPhone\ Simulator -SimulateApplication '
      $log.info "Launching app..."
      @ops.launch_app cmd, app.binary_path
    end

    def self.simulators
      basedir = ENV['HOME'] + '/Library/Application Support/iPhone Simulator'

      return [] unless Dir.exist? basedir

      dirs = Dir.glob("#{basedir}/**")
      raise "No simulators found in #{basedir}." if dirs.length.zero?

      dirs
    end

    def ca_interface
      SimulatorCAInterface.new @sim_dir
    end

    def disconnect
      # nothing to do
    end

    def device?
      false
    end

    def simulator?
      true
    end
  end
end
