class ConsoleLauncher

  def initialize
    @term = "terminator"
  end


  def run cmd
    command = "#{@term} -x sh -c '#{cmd}'"
    puts command
    Process.spawn command

  end


end