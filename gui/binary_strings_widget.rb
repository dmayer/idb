class BinaryStringsWidget < Qt::Widget

  def initialize *args
    super *args
    @layout = Qt::GridLayout.new
    setLayout(@layout)

    @details = Qt::PlainTextEdit.new
    @details.setReadOnly(true)


    @extract = Qt::PushButton.new "Extract Strings"
    @extract.connect(SIGNAL :released) {
      @details.clear
      strings = $selected_app.strings
      @details.appendPlainText(strings)
    }

    @layout.addWidget @details, 0,0
    @layout.addWidget @extract, 1,0




  end

  def refresh

  end

end