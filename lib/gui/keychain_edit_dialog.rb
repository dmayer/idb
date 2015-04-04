
module Idb
  class KeychainEditDialog < Qt::Dialog

    def initialize *args
      super *args

      self.modal = true

      @layout = Qt::GridLayout.new
      setLayout(@layout)
      setWindowTitle("Edit Keychain Item")

      @data_text = Qt::PlainTextEdit.new
      @layout.addWidget @data_text, 0,0,1,2

      @save_button = Qt::PushButton.new "Save"
      @save_button.setDefault true

      @save_button.connect(SIGNAL(:released)) {|x|
        accept()
      }
      @cancel_button = Qt::PushButton.new "Cancel"
      @cancel_button.connect(SIGNAL(:released)) {|x|
        reject()
      }

      @layout.addWidget @save_button, 1, 1
      @layout.addWidget @cancel_button, 1, 0


    end

    def setText text
      @data_text.appendPlainText text
    end

    def getText
      @data_text.toPlainText
    end
  #
  end
end
