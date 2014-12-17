module Idb
  class WeakClassDumpWrapper

    def initialize local_header_dir

      @remote_header_dir_base = "/tmp/weak_class_dump_"
      @remote_header_dir = @remote_header_dir_base + $selected_app.uuid

      @local_header_dir = local_header_dir

    end

    def execute_cycript
      unless $device.cycript_installed?
        $log.error "Cycript not found, aborting."
        return
      end

      # ensure cycript script is installed.
      # originally from: https://github.com/limneos/weak_classdump

      wc_file = "/var/root/weak_classdump.cy"
      unless $device.ops.file_exists?  wc_file
        $log.info "weak_classdump not found, Installing onto device."
        $device.ops.upload("#{File.dirname(File.expand_path(__FILE__))}/../utils/weak_class_dump/weak_classdump.cy", wc_file)
      end

      local_instructions_file = "#{$tmp_path}/weak_classdump_instructions.cy"
      remote_instructions_file = "/var/root/weak_classdump_instructions.cy"
      File.open(local_instructions_file,"w") { |x|
        x.puts("weak_classdump_bundle([NSBundle mainBundle],\"#{@remote_header_dir}\")")
      }

      $device.ops.upload local_instructions_file, remote_instructions_file

      $log.info "Launching app..."
      $selected_app.launch

      cmd = "cycript -p '#{$selected_app.binary_name}' #{wc_file}"
      $log.info "Injecting: #{cmd}"
      $device.ops.execute cmd

      $log.info "Running cycript using weak_classdump."
      cmd = "cycript -p '#{$selected_app.binary_name}' #{remote_instructions_file}"
      $log.info "Running: #{cmd}"
      $device.ops.execute cmd

    end

    def get_header_files
      Dir.entries(@local_header_dir).reject{|entry| entry == "." || entry == ".."}
    end

    def pull_header_files
      $log.info "Downloading header files from #{@remote_header_dir} to #{@local_header_dir}"
      $device.ops.download_recursive(@remote_header_dir, @local_header_dir)
    end



  end
end