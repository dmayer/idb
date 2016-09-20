require 'awesome_print'

module Idb
  class OtoolWrapper
    attr_accessor :load_commands, :shared_libraries, :pie, :arc, :canaries

    def initialize binary
      @otool_path = "/usr/bin/otool"
      unless File.exist? @otool_path.to_s
        $log.error "otool not available. Some functions will not work properly."
        error = Qt::MessageBox.new
        error.setInformativeText("This feature requires  otool to be installed on the host running idb. This is the default on OS X but it may not be available for other platforms.")
        error.setIcon(Qt::MessageBox::Critical)
        error.exec
        @otool_path = nil

        return
      end

      @binary = binary
      parse_load_commands
      parse_shared_libraries
      parse_header
      process_symbol_table
    end


    private
    def parse_shared_libraries
      if @otool_path.nil?
        @shared_libraries = Array.new
        @shared_libraries << "Error; otool not available"
        return
      end
      @raw_shared_libraries_output = `#{@otool_path} -L '#{@binary}'`
      lines = @raw_shared_libraries_output.split("\n")
      @shared_libraries = lines[1,lines.size].map{ |x| x.strip} unless lines.nil?
    end

    def process_symbol_table
      if @otool_path.nil?
        @canaries = "Error"
        @arc = "Error"
        return
      end
      symbols = `#{@otool_path} -I -v '#{@binary}'`
      if symbols.include? "stack_chk_fail" or symbols.include? "stack_chk_guard"
        @canaries = true
      else
        @canaries = false
      end

      if symbols.include? "_objc_release"
        @arc = true
      else
        @arc = false
      end
    end


    def hashify_otool_output(otool_output)
      # otool output may contain multiple mach headers
      mach_headers = otool_output.split("Mach header\n").map(&:strip)

      # The newest otool version no longer echos the path of the binary being
      # inspected. Here we reject that line if it shows up in the output of
      # otool as well as any blank lines
      mach_headers.reject!{|line| line == "" or line.include?(@binary)}

      # convert otool output to a hash
      mach_headers.map do |mach_header|
        mach_hash = {}
        headers, values = mach_header.split("\n").map(&:split)
        headers.each_with_index do |header, index|
          mach_hash[header] = values[index]
        end
        mach_hash
      end
    end


    def parse_header
      if @otool_path.nil?
        @pie = "Error"
        return
      end
      pie_flag = 0x00200000
      @raw_load_output = `#{@otool_path} -h '#{@binary}'`


      mach_hashes = hashify_otool_output(@raw_load_output)
      $log.info "Mach Hashes: #{mach_hashes}"

      # extract the Position Independent Executable (PIE) flag from the flags
      # value.
      mach_hashes.each do |mach_hash|
        if (mach_hash["flags"].to_i(16) & pie_flag) == pie_flag
          @pie = true
        else
          @pie = false
        end
      end
    end

    def parse_load_commands
      if @otool_path.nil?
        @load_commands = nil
        return
      end
      @raw_load_output = `#{@otool_path} -l '#{@binary}'`
      delim = "Load command"
      regex_cmd = /Load command (\d+)/
      regex_parse_key_vals = /\s*(cmd|cryptid)\s(.+)/

      @load_commands = Hash.new

      @raw_load_output.split("\n").each {|line|

        if match = regex_cmd.match(line)
          @load_commands[@cmd] = @command unless @cmd.nil?
          @cmd = match[1]
          @command = Hash.new
        end

        if match = regex_parse_key_vals.match(line)
          @command[match[1]] = match[2]
        end
      }
    end
  end
end
