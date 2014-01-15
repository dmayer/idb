class LogPlainTextEdit < Qt::PlainTextEdit

  def initialize *args
    super *args


  end

  def append_message text

    appendHtml(text);
    verticalScrollBar.setValue(verticalScrollBar.maximum)
  end


end