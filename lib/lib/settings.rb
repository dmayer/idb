# encoding: utf-8
require 'yaml'

#YAML::ENGINE.yamler='psych'

module Idb
  class Settings

    def initialize file_name
      @file_name = file_name
      if file_name.nil?
        @data = Hash.new
      else
        if not self.load
          @data = Hash.new
        end
      end
    end


    def load
      if File.exist? @file_name
        $log.info "Loading configuration from #{@file_name}"
        @data = YAML.load(File.open(@file_name).read)
        @data["idb_utility_port"] = "4711" if @data["idb_utility_port"].nil?
        true
      else
        $log.warn "No configuration found, generating default."
        @data = Hash.new
        @data["ssh_host"] = "localhost"
        @data["ssh_port"] = 22
        @data["ssh_username"] = "root"
        @data["ssh_password"] = "alpine"
        @data["manual_ssh_port"] = "2222"
        @data["idb_utility_port"] = "4711"
        @data["device_connection_mode"] = "usb"
        $log.info "Storing new configuration at #{@file_name}"
        store
        load
      end
    end

    def store
      $log.info "Storing new configuration at #{@file_name}."
      conf_file = File.open(@file_name,"w")
      conf_file.puts(@data.to_yaml)
      conf_file.close
    end

    private
    def method_missing(method, *args, &block)
      m = method.to_s
      if @data.has_key?(m)
        return @data[m]
      elsif @data.has_key?(m.to_sym)
        return @data[m.to_sym]
      end
      begin
        @data.send(method, *args, &block)
      rescue
        nil
      end
    end


  end
end
