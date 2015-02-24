require_relative 'keychain_text_widget'
require_relative 'keychain_binary_widget'

module Idb

  class KeychainTabWidget < Qt::TabWidget

    def initialize *args
      super *args

      @tabs = Hash.new

      @text = KeychainTextWidget.new self
      @tabs[:text] = addTab(@text, "Text Data")

      @binary = KeychainBinaryWidget.new self
      @tabs[:binary] = addTab(@binary, "Binary VData")

      @gena = KeychainTextWidget.new self
      @tabs[:gena] = addTab(@gena, "gena")

    end


    def set_gena text
      @gena.clear
      @gena.set_data text
    end

    def set_data text
      @text.clear
      @text.set_data text
    end

    def set_vdata text
      @binary.clear
      @binary.set_data text
    end

    def clear
      @text.clear
      @binary.clear
    end

  end
end
