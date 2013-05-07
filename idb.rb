require 'readline'
require_relative 'options_handler'
require_relative 'simulator_idb'
require_relative 'auto_complete_handlers'

# Store the state of the terminal
stty_save = `stty -g`.chomp


options = OptionsHandler.new.parse()


if options[:simulator]
  $idb = SimulatorIDB.new
else
  puts "Unimplemented"
  exit
end



while line = Readline.readline('idb > ', true)
  case line.split(" ").first
    when "quit", "exit"
      exit
    when "install"
      $idb.handle_install line
  end
end

