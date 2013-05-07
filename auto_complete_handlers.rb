# autocomplete
LIST = [
    'install', 'download', 'set',
    'help', 'quit', 'exit',
].sort

comp = proc { |s|
  puts "Current line: #{Readline.line_buffer}"

  LIST.grep( /^#{Regexp.escape(s)}/ )
}

Readline.completion_append_character = " "
Readline.completion_proc = comp

