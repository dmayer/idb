require_relative 'otool_wrapper'
require_relative 'app'

module Idb
  class AppBinary
    attr_writer :decrypted_path
    def initialize(app_binary)
      @otool = OtoolWrapper.new app_binary
    end

    def shared_libraries
      @otool.shared_libraries
    end

    def pie?
      @otool.pie
    end

    def stack_protected?
      @otool.canaries
    end

    def arc?
      @otool.arc
    end

    def encrypted?
      encrypted = false
      return "Error" if @otool.load_commands.nil?
      @otool.load_commands.each do |_key, val|
        if val['cmd'].strip.start_with?('LC_ENCRYPTION_INFO') && (val['cryptid'].strip == 1.to_s)
          encrypted =  true
        end
      end
      encrypted
    end

    def cryptid
      return "Error" if @otool.load_commands.nil?
      @otool.load_commands.each do |_key, val|
        return val['cryptid'] if val['cmd'] == 'LC_ENCRYPTION_INFO'
      end
      nil
    end
  end
end
