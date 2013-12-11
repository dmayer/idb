require 'net/ssh'
require 'net/sftp'

class SSHOperations
  attr_accessor :ssh

  def initialize username, password, hostname, port
    @hostname = hostname
    @username = username
    @password = password
    @port = port

    $log.info 'Establishing SSH Session...'
    @ssh = Net::SSH.start hostname, username, :password => password, :port => port

    # initiali:wze sftp connection and wait until it is open
    $log.info 'Establishing SFTP Session...'
    @sftp = Net::SFTP::Session.new @ssh
    @sftp.loop { @sftp.opening? }

  end

  def disconnect
    puts "[*] Closing SSH Session"
    @ssh.close
  end


  def execute(command)
    @ssh.exec! command
  end

  def download(remote_path, local_path = nil)
    begin
      if local_path.nil?
        @sftp.download! remote_path
      else
        @sftp.download! remote_path, local_path
      end
    rescue
      puts "Error downloading file."
      return false
    end
    return true

  end

  def upload(local_path, remote_path)
    @sftp.upload! local_path, remote_path
  end

  def list_dir dir

    @sftp.dir.entries(dir).map {|x| x.name}
  end

  def file_exists? path
    begin
      @sftp.stat!(path)
      return true
    rescue
      return false
    end

  end

  def launch path
    @ssh.exec path
  end

  def dir_glob path, pattern
    @sftp.dir.glob(path,pattern).map {|x| "#{path}/#{x.name}"}
  end

  def directory? path
    @sftp.stat!(path).directory?
  end

  def file? path
    begin
      @sftp.stat!(path).file?
    rescue
      false
    end
  end

  def mtime path
    Time.new @sftp.stat!(path).mtime
  end

  def open path
    Launchy.open path
  end

  def launch_app command, app
    puts "#{command} \"#{app}\""
    self.execute("#{command} \"#{app}\"")
  end

end