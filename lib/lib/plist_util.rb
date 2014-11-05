require 'plist4r'
require 'rbconfig'
require 'nokogiri'
require 'coderay'

module Idb
  class PlistUtil

    attr_accessor :schemas, :binary_name, :bundle_identifier, :plist_data, :plist_file

    def initialize(plist_file)
      @plist_file = plist_file

      @plutil = Pathname.new("/usr/bin/plutil")
      if(!@plutil.exist?)
        @plutil = Pathname.new("/usr/bin/plistutil")
          if(!@plutil.exist?)
            raise "plutil not found at #{@plutil}. aborting."
          end
      end

      parse_plist_file
    end

    def parse_info_plist
      extract_binary_name
      extract_url_handlers
    end

    def dump
      doc = Nokogiri::XML(File.open(@plist_file)) do |config|
        config.nonet.noblanks
      end
        puts CodeRay.scan(doc.to_xml(:indent => 2), :xml).terminal
    end

    def get_with_regex regex
      ap @plist_data.to_hash
      a = @plist_data.to_hash.find { |x|
        not (x =~ regex).nil?
      }
      ap a
      a
    end

    private
    def parse_plist_file
      $log.info 'Parsing plist file..'

      # Make sure plist file is in xml and not binary
      if RbConfig::CONFIG['host_os'] =~ /linux/
        `#{@plutil.realpath}  -i "#{@plist_file}" -o "#{@plist_file}"`
      else
        `#{@plutil.realpath} -convert xml1 "#{@plist_file}"`
      end

  #    @plist_data = Plist::parse_xml(@plist_file)
      @plist_data = Plist4r.open @plist_file
    end

    def extract_url_handlers
      @schemas = Array.new

      if @plist_data['CFBundleURLTypes'] != nil
        for type in @plist_data['CFBundleURLTypes']
          if !type.nil? and !type['CFBundleURLSchemes'].nil?
            @schemas += type['CFBundleURLSchemes']
          else
            @schemas += ['None']
          end
        end
      end
    end

    def extract_binary_name
      @binary_name = @plist_data['CFBundleExecutable']
      @bundle_identifier =  @plist_data['CFBundleIdentifier']
    end





  end
end