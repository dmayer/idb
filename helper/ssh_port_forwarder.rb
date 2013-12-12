#!/usr/bin/env ruby
require_relative '../lib/ssh_port_forwarder'
require_relative '../lib/settings'
require_relative '../lib/usb_muxd_wrapper'
require 'log4r'

def run

  # initialize log
  $log = Log4r::Logger.new 'port_forward'
  outputter = Log4r::Outputter.stdout
  outputter.formatter =  Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %m")
  $log.outputters = [ outputter ]

  # load settings
  settings  = Settings.new 'config/settings.yml'

  if settings['device_connection_mode'] == "ssh"
    $log.debug "Connecting via SSH"

    # setup forwards
    $ssh_forwards = SSHPortForwarder.new settings['ssh_username'], settings['ssh_password'], settings['ssh_host'], settings['ssh_port']
  else
    $log.debug "Connecting via USB"

    $usbmuxd = USBMuxdWrapper.new
    proxy_port = $usbmuxd.find_available_port
    $log.debug "Using port #{proxy_port} for SSH forwarding"

    $usbmuxd.proxy proxy_port, settings['ssh_port']
    # setup forwards
    $ssh_forwards = SSHPortForwarder.new settings['ssh_username'], settings['ssh_password'], 'localhost', proxy_port
  end


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
  $log.info "Closing SSH connection"
  $ssh_forwards.stop
  $log.info "Stopping any SSH via USB forwarding"
  $usbmuxd.stop_all
end
