
module Idb
  class KeychainTextWidget < Qt::Widget

    attr_accessor :data_text, :vdata_text

    def initialize *args
      super *args
      @layout = Qt::GridLayout.new
      setLayout(@layout)

      @data_text = Qt::PlainTextEdit.new
      @data_text.setReadOnly(true)
      @layout.addWidget @data_text, 0, 0

    end

    def set_data data
      @data_text.appendPlainText data.to_s
    end

    def clear
      @data_text.clear
    end


  end
end