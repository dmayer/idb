#!/usr/bin/env ruby
require_relative '../lib/ssh_port_forwarder'
require_relative '../lib/settings'
require_relative '../lib/usb_muxd_wrapper'
require 'log4r'

module Idb
  class SSHPortForwarderHelper
    def self.run

      # initialize log
      $log = Log4r::Logger.new 'port_forward'
      outputter = Log4r::Outputter.stdout
      outputter.formatter =  Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %c ::  %m")
      $log.outputters = [ outputter ]

      # load settings
      settings_path = File.dirname(ENV['HOME'] + "/.idb/config/")
      settings_filename = "settings.yml"
      settings = Settings.new "#{settings_path}/#{settings_filename}"

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

      # Special idb internal port
      $ssh_forwards.add_remote_forward Integer(settings['idb_utility_port']), 'localhost', Integer(settings['idb_utility_port'])

      unless settings['remote_forwards'].nil?
        settings['remote_forwards'].each { |x|
          $ssh_forwards.add_remote_forward Integer(x['remote_port']), x['local_host'], Integer(x['local_port'])
        }
      end

      unless settings['local_forwards'].nil?
        settings['local_forwards'].each { |x|
          $ssh_forwards.add_local_forward Integer(x['local_port']), x['remote_host'], Integer(x['remote_port'])
        }
      end

      # start event loop
      $ssh_forwards.start
    end
  end

  begin
    SSHPortForwarderHelper.run
  rescue SystemExit, Interrupt
    $log.info "Cleaning up before exiting"
    $log.info "Closing SSH connection"
    $ssh_forwards.stop
    $log.info "Stopping any SSH via USB forwarding"
    $usbmuxd.stop_all
  end

end
