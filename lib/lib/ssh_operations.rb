require 'net/ssh'
require 'net/sftp'
require 'launchy'

module Idb
  class SSHOperations
    attr_accessor :ssh

    def initialize(username, password, hostname, port)
      @hostname = hostname
      @username = username
      @password = password
      @port = port
      $log.info "Establishing SSH Session for #{username}@#{hostname}:#{port}"
      connect
    end

    def connect
      @ssh = Net::SSH.start @hostname, @username, password: @password, port: @port

      # initialize sftp connection and wait until it is open
      $log.info 'Establishing SFTP Session...'
      @sftp = Net::SFTP::Session.new @ssh
      @sftp.loop { @sftp.opening? }
      unless @sftp.open?
        $log.error 'SFTP connection could not be established.'
        error = Qt::MessageBox.new
        error.setInformativeText("SFTP connection could not be established. Ensure SFTP is available on the iOS device, e.g., by installing the OpenSSH package.")
        error.setIcon(Qt::MessageBox::Critical)
        error.exec
      end
    rescue StandardError => ex
      error = Qt::MessageBox.new
      error.setInformativeText("SSH connection could not be established: #{ex.message}")
      error.setIcon(Qt::MessageBox::Critical)
      error.exec
    end

    def disconnect
      puts "[*] Closing SSH Session"
      @ssh.close
    end

    def execute(command, opts = {})
      command = "su - #{opts[:as_user]} -c \"#{command}\"" if opts[:as_user]

      if opts[:non_blocking]
        $log.debug "Executing non-blocking SSH command: #{command}"
        @ssh.exec command
      else
        $log.debug "Executing blocking SSH command: #{command}"
        @ssh.exec! command
      end
    end

    def chmod(file, permissions)
      @sftp.setstat(file, permissions: permissions)
    end

    def download_recursive(remote_path, local_path)
      @sftp.download! remote_path, local_path, recursive: true
    rescue
      $log.error "Failed to download #{remote_path}."
      return false
    end

    def download(remote_path, local_path = nil)
      begin
        if local_path.nil?
          @sftp.download! remote_path
        else
          @sftp.download! remote_path, local_path
        end
      rescue
        $log.error "Error downloading file."
        return false
      end
      true
    end

    def upload(local_path, remote_path)
      @sftp.upload! local_path, remote_path
    end

    def list_dir(dir)
      @sftp.dir.entries(dir).map(&:name)
    end

    def list_dir_full(dir)
      @sftp.dir.entries(dir)
    end

    def file_exists?(path)
      @sftp.stat!(path)
      return true
    rescue Exception => e
      $log.debug("File not found: #{e.message}")
      return false
    end

    def launch(path)
      @ssh.exec path
    end

    def dir_glob(path, pattern)
      @sftp.dir.glob(path, pattern).map { |x| "#{path}/#{x.name}" }
    end

    def mkdir(path)
      @sftp.mkdir path
    end

    def directory?(path)
      @sftp.stat!(path).directory?
    rescue
      nil
    end

    def file?(path)
      @sftp.stat!(path).file?
    rescue
      false
    end

    def mtime(path)
      Time.new @sftp.stat!(path).mtime
    end

    def open(path)
      Launchy.open path
    end

    def launch_app(command, app)
      puts "#{command} \"#{app}\""
      execute("#{command} \"#{app}\"")
    end
  end
end
