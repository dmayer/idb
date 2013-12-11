#!/usr/bin/env ruby
require_relative '../lib/ssh_port_forwarder'
require_relative '../lib/settings'
require 'log4r'

def run

  # initialize log
  $log = Log4r::Logger.new ''
  outputter = Log4r::Outputter.stdout
  outputter.formatter =  Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %m")
  $log.outputters = [ outputter ]

  # load settings
  settings  = Settings.new 'config/settings.yml'

  # setup forwards
  $ssh_forwards = SSHPortForwarder.new settings['ssh_username'], settings['ssh_password'], settings['ssh_host'], 4444
  $log.info 'Setting up port forwarding...'

  settings['remote_forwards'].each { |x|
    $ssh_forwards.add_remote_forward Integer(x['remote_port']), x['local_host'], Integer(x['local_port'])
  }

  # start event loop
  $ssh_forwards.start
end


begin
  run
rescue SystemExit, Interrupt
  $log.info "Cleaning up before exiting"
  $ssh_forwards.stop
end
