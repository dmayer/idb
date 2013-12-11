require 'net/ssh'
require 'log4r'


class SSHPortForwarder

  def initialize username, password, hostname, port
    # initialize log
    @log = Log4r::Logger.new ''
    outputter = Log4r::Outputter.stdout
    outputter.formatter =  Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %m")

    @log.outputters = [ outputter ]

    @log.info 'Establishing SSH port forwarding...'
    @ssh = Net::SSH.start hostname, username, :password => password, :port => port
  end

  def add_remote_forward remote_port, local_host, local_port
    @log.info " - Forwarding remote:#{remote_port} -> #{local_host}:#{local_port}"
    @ssh.forward.remote_to local_port, local_host, remote_port
  end

  def start
    @ssh.loop {
        true
      }
  end

  def stop
    $log.info "Closing SSH connection."
    @ssh.close
  end


end