require 'optparse'

class OptionsHandler
  attr_accessor :options

  def initialize()
    @options = {}
  end

  def parse()
    OptionParser.new do |opts|
      opts.banner = "Usage: idb.rb [options]"
      opts.on("-s", "--simulator", "Use iOS Simulator.") do |u|
        @options[:simulator] = true
      end
      opts.on("-p", "--pass PASSWORD") do |p|
        @options[:pass] = p
      end
      opts.on("-i", "--ip_addr IP_ADDRESS") do |i|
        @options[:ip_addr] = i
      end
      opts.on("-v", "--verbose") do |v|
        @options[:verbose] = v
      end
      opts.on_tail("-h","--help","Show this message") do
        puts opts
        exit
      end
    end.parse!
    validate()
    return @options
  end

  def validate()
    begin
      mandatorySwitches = [:simulator]
      miss = mandatorySwitches.select { |param| @options[param].nil? }
      if not miss.empty?
        puts "Missing Required Options: #{miss.join(', ')}"
        puts @options
        puts "Please check your command line arguments!  Exiting!"
        exit
      end
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!.to_s
      puts @options
      exit
    end
  end
end
