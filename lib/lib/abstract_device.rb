module Idb
  class AbstractDevice
    attr_accessor :apps_dir
    attr_accessor :ops


    def get_app_uuids
      if not @ops.file_exists? @apps_dir
        puts "Application directory #{@apps_dir} not found."
        raise "Application directory #{@apps_dir} not found."
      end

      puts '[*] Retrieving list of applications...'

      dirs =  @ops.list_dir "#{@apps_dir}"
      dirs.select! { |x| x != "." and x != ".." }

      if dirs.length == 0
        puts "No applications found in #{@apps_dir}."
        raise "No applications found in #{@apps_dir}."
      end
      return dirs
    end

    def close

    end


  end
end