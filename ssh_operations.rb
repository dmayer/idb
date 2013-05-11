require 'net/ssh'
require 'net/sftp'

class SSHOperations

  def initialize username, password, hostname, port
    @hostname = hostname
    @username = username
    @password = password
    @port = port

    puts "[*] Establishing SSH Session..."
    @ssh = Net::SSH.start hostname, username, :password => password, :port => port

    # initiali:wze sftp connection and wait until it is open
    puts "[*] Establishing SFTP Session..."
    @sftp = Net::SFTP::Session.new @ssh
    @sftp.loop { @sftp.opening? }

  end


  def execute command
    @ssh.exec! command
  end

  def download remote_path
    @sftp.download!(remote_path)
  end

  def download remote_path, local_path
    @sftp.download!(remote_path, local_path)
  end

  def upload local_path, remote_path
    @sftp.upload local_path, remote_path
  end

  def list_dir dir

    @sftp.dir.entries(dir).map {|x| "#{dir}/#{x.name}"}
  end

  def file_exists? path
    begin
      @sftp.stat!(path)
      return true
    rescue
      return false
    end

  end

  def dir_glob path, pattern
    @sftp.dir.glob(path,pattern).map {|x| "#{path}/#{x.name}"}
  end

  def directory? path
    puts "directory?"
    puts path
    @sftp.stat!(path).directory?
  end

  def file? path
    @sftp.stat!(path).file?

  end

  def mtime path
    @sftp.stat!(path).mtime
  end

end