class ConsoleLauncher

  def initialize
    # if os x
    #'/Applications/iTerm.app'
#   '/Applications/Utilities/Terminal.app/ '
    #if linux
    # terminator, gnome-terminal, Konsole(?), xterm
    @term = "terminator"
  end


  def run cmd
    command = "#{@term} -x sh -c '#{cmd}'"
    puts command
    Process.spawn command

  end



end