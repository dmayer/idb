require 'awesome_print'

class OtoolWrapper
  attr_accessor :load_commands, :shared_libraries, :pie

  def initialize binary
    @otool_path = "/usr/bin/otool"
    @binary = binary
    parse_load_commands
    parse_shared_libraries
    parse_header
  end


  private
  def parse_shared_libraries
    @raw_shared_libraries_output = `#{@otool_path} -L '#{@binary}'`
    lines = @raw_shared_libraries_output.split("\n")
    @shared_libraries = lines[1,lines.size].map{ |x| x.strip} unless lines.nil?
  end

  def parse_header
    pie_flag = 0x00200000
    @raw_load_output = `#{@otool_path} -h '#{@binary}'`

    # fourth row contains values. then split them up.
    vals = @raw_load_output.split("\n")[3].split(" ")

    #7th field contains the flags
    flags = vals[7].to_i(16)

    if flags & pie_flag == pie_flag
      @pie = true
    else
      @pie = false
    end


  end

  def parse_load_commands
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

