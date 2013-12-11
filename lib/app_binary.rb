require_relative 'otool_wrapper'
require_relative 'app'

class AppBinary

  def initialize app_binary
    @otool = OtoolWrapper.new app_binary
  end

  def get_shared_libraries
    @otool.shared_libraries
  end


  def is_encrypted?
    @otool.load_commands.each {|key, val|
      if val['cmd'] == 'LC_ENCRYPTION_INFO' and val['cryptid'] == 1.to_s
        return true
      end
    }
    return false
  end

  def get_cryptid
    @otool.load_commands.each {|key, val|
      if val['cmd'] == 'LC_ENCRYPTION_INFO'
        return val['cryptid']
      end
    }
    return nil
  end
end