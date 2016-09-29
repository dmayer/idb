module Idb
  class BinaryStringsWidget < Qt::Widget
    def initialize(*args)
      super(*args)
      @layout = Qt::GridLayout.new
      setLayout(@layout)

      @details = Qt::PlainTextEdit.new
      @details.setReadOnly(true)

      @extract = Qt::PushButton.new "Extract Strings"
      @extract.connect(SIGNAL(:released)) do
        @details.clear
        strings = $selected_app.strings
        @details.appendPlainText(strings)
      end

      @layout.addWidget @details, 0, 0
      @layout.addWidget @extract, 1, 0
    end

    def refresh
    end
  end
end
