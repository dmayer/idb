require_relative 'otool_wrapper'
require_relative 'app'

class AppBinary

  def initialize app_binary
    @otool = OtoolWrapper.new app_binary
  end

  def get_shared_libraries
    @otool.shared_libraries
  end

  def setDecryptedPath path
    @decrypted_path = path
  end

  def is_pie?
    @otool.pie
  end


  def is_encrypted?
    encrypted = false
    @otool.load_commands.each {|key, val|
      if val['cmd'].strip == 'LC_ENCRYPTION_INFO' and val['cryptid'].strip == 1.to_s
        encrypted =  true
      end
    }
    return encrypted
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