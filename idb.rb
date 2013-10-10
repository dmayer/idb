#!/usr/bin/env ruby

require 'readline'
require 'trollop'
require_relative 'simulator_idb'
require_relative 'device_idb'
require_relative 'auto_complete_handlers'

# Store the state of the terminal
stty_save = `stty -g`.chomp

options = Trollop::options do
  version "v1.0 (c) 2013 Daniel A. Mayer, Matasano Security"
  banner <<-EOS
Command line utility to perform common tasks on iDevices and the iOS simulator.

Usage:
       ruby irb.rb [options] [optional command]

if [optional command] is specified, it is executed and idb exits. If it is omitted,
 an intractive idb prompt is displayed

Valid [options] are:

EOS
  opt :simulator, "Use simulator", :default => false, :type => :boolean
  opt :device, "Use iOS device via SSH", :default => false, :type => :boolean
  opt :username, "SSH username", :type => :string, :default => "root"
  opt :password, "SSH password", :type => :string
  opt :hostname, "SSH hostname", :type => :string
  opt :port, "SSH port", :type => :int, :default => 22
  conflicts :simulator, :device
  depends :device, :password, :hostname
end

Trollop::die "requires either --simulator or --device" unless options[:simulator] || options[:device]


if options[:simulator]
  $idb = SimulatorIDB.new
else
  $idb = DeviceIDB.new options[:username], options[:password], options[:hostname], options[:port]
end

def process_command line
  case line.split(" ").first
    when "quit", "exit"
      exit
    when "install"
      $idb.handle_install line
    when "cert"
      $idb.handle_cert line
    when "screenshot"
      $idb.handle_screen_shot line
    when "list"
      # make this list app also add list handlers etc.
      $idb.handle_list
    when "app"
      $idb.handle_app line
    when "help"
      puts "install - Install various utilities."
      puts "cert - Installs certificates in simulator key store."
      puts "screenshot - Util to detect if an app stores screenshots on backgrounding."
      puts "app - Various application related tools (list, download, decrypt)"
    else
      puts "Command not found. Try 'help'"

  end

end

if not ARGV[0].nil?
  command = ARGV.join(' ')
  process_command command
  exit
end

$prompt = 'idb > '

while line = Readline.readline($prompt, true)
  process_command line
end

