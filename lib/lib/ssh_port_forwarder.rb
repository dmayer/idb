require 'net/ssh'
require 'log4r'

module Idb
  class SSHPortForwarder
    def initialize(username, password, hostname, port)
      # initialize log
      @log = Log4r::Logger.new 'port_forward'
      outputter = Log4r::Outputter.stdout
      outputter.formatter = Log4r::PatternFormatter.new(pattern: "[%l] %d :: %c :: %m")

      @log.outputters = [outputter]

      @log.info 'Establishing SSH port forwarding...'
      @ssh = Net::SSH.start hostname, username, password: password, port: port
    end

    def add_local_forward(local_port, remote_host, remote_port)
      @log.info " - Forwarding local:#{local_port} -> #{remote_host}:#{remote_port}"
      @ssh.forward.local local_port, remote_host, remote_port
    end

    def add_remote_forward(remote_port, local_host, local_port)
      @log.info " - Forwarding remote:#{remote_port} -> #{local_host}:#{local_port}"
      @ssh.forward.remote_to local_port, local_host, remote_port
    end

    def start
      @ssh.loop do
        true
      end
    end

    def stop
      $log.info "Closing SSH connection."
      @ssh.close
    end
  end
end
