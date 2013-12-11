require_relative 'abstract_device'
require_relative 'simulator_ca_interface'
require_relative 'local_operations'

class Simulator < AbstractDevice
  attr_accessor :sim_dir

  def initialize sim_dir
    puts "Initializing simulator with #{sim_dir}"
    @sim_dir = sim_dir
    @apps_dir = @sim_dir + "/Applications"
    @ops = LocalOperations.new

  end



  def self.get_simulators
    basedir = ENV['HOME'] + '/Library/Application Support/iPhone Simulator'
    unless Dir.exists? basedir
      raise "No simulators found in #{basedir}."
    end

    dirs = Dir.glob("#{basedir}/**")
    if dirs.length == 0
      raise "No simulators found in #{basedir}."
    end

    return dirs
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