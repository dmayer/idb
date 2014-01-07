require 'socket'
require 'awesome_print'

class USBMuxdWrapper
  def initialize
    @proxy_pids = Array.new
  end

  def find_available_port
    x = TCPServer.new("127.0.0.1",0)
    @port= x.addr[1]
    x.close
    @port
  end

  def proxy local_port, remote_port
    $log.info "Launching SSH proxy on port #{local_port}"
    @proxy_pids << Process.spawn("iproxy #{local_port} #{remote_port}")
    @proxy_pids.last
  end

  def stop_all
    @proxy_pids.each { |pid|
      $log.info "Terminating proxy with pid #{pid}"
      Process.kill("INT", pid)
    }
  end


end
