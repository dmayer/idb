require 'openssl'
require 'digest/sha1'
require 'sqlite3'
require_relative 'ca_interface'

class SimulatorCAInterface < CAInterface

  def initialize sim_path
    @sim_path = sim_path
    @store_path = "/Library/Keychains/TrustStore.sqlite3"
    @db_path = @sim_path + @store_path
  end

end
