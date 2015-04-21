require_relative 'keychain_text_widget'
require_relative 'keychain_binary_widget'

module Idb

  class KeychainTabWidget < Qt::TabWidget

    def initialize *args
      super *args

      @tabs = Hash.new

      @text = KeychainTextWidget.new self
      @tabs[:text] = addTab(@text, "Data")

      @binary = KeychainBinaryWidget.new self
      @tabs[:binary] = addTab(@binary, "Hexdump")

      @plist = KeychainTextWidget.new self
      @tabs[:plist] = addTab(@plist, "View Plist")

    end


    def set_plist text
      xml = "Not a plist file."
      if text.start_with? "bplist"
        begin
          file = Tempfile.new('plist')
          file.write text
          file.close
          parsed = PlistUtil.new file.path
          xml = parsed.get_xml
        rescue
          xml = "Data could not be parsed as Plist."
        end
      end

      @plist.clear
      @plist.set_data  xml
      file.unlink unless file.nil?
    end

    def set_data text
      @text.clear
      @text.set_data text
    end

    def set_hexdata text
      @binary.clear
      @binary.set_data text
    end

    def clear
      @text.clear
      @binary.clear
    end

  end
end
