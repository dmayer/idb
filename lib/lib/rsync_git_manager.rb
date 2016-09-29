require 'git'
require 'pty'
require 'expect'

module Idb
  class RsyncGitManager
    def initialize(local_path)
      @local_path = local_path
      FileUtils.mkdir_p @local_path unless Dir.exist? @local_path

      begin
        @g = Git.open(local_path, log: $log)
      rescue
        $log.debug "Repository could not be opened." \
                   " This is likely the first clone. Creating empty repo."
        Git.init(local_path)
        @g = Git.open(local_path, log: $log)
        FileUtils.touch "#{local_path}/idb_dummy.placeholder"
        @g.add(all: true)
        $log.debug "Committing placeholder to initialize the repo."
        begin
          @g.commit_all("Initial commit. Initializing the repo.")
        rescue
          $log.error "Initial commit failed."
        end

      end
    end

    def sync_dir(remote, local_relative)
      local = @local_path + "/" + local_relative
      if $settings['device_connection_mode'] == "ssh"
        cmd = "rsync -avz -e 'ssh -oStrictHostKeyChecking=no  -p #{$settings.ssh_port}'" \
              "  #{$settings.ssh_username}@#{$settings.ssh_host}:#{Shellwords.escape(remote)}/" \
              " #{Shellwords.escape(local)}/"
      else
        cmd = "rsync -avz -e 'ssh -oStrictHostKeyChecking=no" \
              "  -p #{$device.tool_port}'  root@localhost:#{Shellwords.escape(remote)}/" \
              " #{Shellwords.escape(local)}/"
      end

      $log.info "Executing rsync command #{cmd}"
      begin
        PTY.spawn(cmd) do |rsync_out, rsync_in, _pid|
          STDOUT.flush
          rsync_out.sync = true
          rsync_in.sync = true
          $expect_verbose = true

          rsync_out.expect(/assword: /) do |_x|
            begin
              $log.info "Supplying password for rsync if required..."
              rsync_in.printf("#{$settings.ssh_password}\n")
            rescue
              $log.info "No password required for rsync...."
            end
          end

          rsync_out.each do |x|
            $log.info x
          end
          PTY.check
        end
      rescue
        $log.error "Something went wrong"
      end
    end

    def commit_new_revision
      $log.info "Rsync Done. committing to git."
      @g.add(all: true)
      begin
        @g.commit_all("Snapshot from #{Time.now}")
      rescue
        $log.error "Something went wrong"
      end
    end

    def start_new_revision
      $log.info "Hard resetting work dir #{@local_path}..."
      begin
        @g.reset_hard
      rescue
        $log.error "Reset of repo failed. If this is the first time you" \
                   " run rsync+git for this app this may be okay."
      end
    end
  end
end
