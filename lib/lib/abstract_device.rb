module Idb
  class AbstractDevice
    attr_accessor :apps_dir
    attr_accessor :ops

    def app_uuids
      unless @ops.file_exists? @apps_dir
        puts "Application directory #{@apps_dir} not found."
        raise "Application directory #{@apps_dir} not found."
      end

      puts '[*] Retrieving list of applications...'

      dirs = @ops.list_dir @apps_dir.to_s
      dirs.select! { |x| (x != ".") && (x != "..") }

      if dirs.length.zero?
        puts "No applications found in #{@apps_dir}."
        raise "No applications found in #{@apps_dir}."
      end
      dirs
    end

    def close
    end
  end
end
