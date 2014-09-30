module Idb
  class ConsoleWidget < Qt::PlainTextEdit

    signals "command(QString)"

    def initialize *args
      super *args
      setPrompt("> ")
      @locked = false
      @history_down = Array.new
      @history_up = Array.new
    end

    def keyPressEvent e, callSuper=false
      if callSuper
        super e
      end
      if @locked
        return
      end

      case e.key
        when Qt::Key_Return
          handleEnter

        when Qt::Key_Backspace
          handleLeft e

        when Qt::Key_Up
          handleHistoryUp

        when Qt::Key_Down
          handleHistoryDown

        when Qt::Key_Left
          handleLeft e

        when Qt::Key_Home
          handleHome
        else
          super e
      end
    end

    def handleEnter
      cmd = getCommand

      if 0 < cmd.length
        while @history_down.count > 0
            @history_up.push(@history_down.pop)
        end
        @history_up.push cmd
      end

      moveToEndOfLine

      if cmd.length > 0
        @locked = true
        setFocus
        insertPlainText("\n")
        emit command(cmd)
      else
        insertPlainText("\n")
        insertPlainText(@userPrompt)
        ensureCursorVisible
      end
    end

    def result result
      insertPlainText(result)
      insertPlainText("\n")
      insertPlainText(@userPrompt)
      ensureCursorVisible
      @locked = false
    end

    def append text
      insertPlainText(text)
      insertPlainText("\n")
      ensureCursorVisible
    end

    def handleHistoryUp
      if 0 < @history_up.count
        cmd = @history_up.pop
        @history_down.push(cmd)

        clearLine
        insertPlainText(cmd)
      end

      historySkip = true
    end

    def handleHistoryDown
      if 0 < @history_down.count && historySkip
        @history_up.push(@history_down.pop)
        historySkip = false
      end

      if 0 < @history_down.count
        cmd = @history_down.pop()
        @history_up.push(cmd)

        clearLine()
        insertPlainText(cmd)
      else
        clearLine()
      end
    end


    def clearLine
      c = textCursor()
      c.select(Qt::TextCursor::LineUnderCursor)
      c.removeSelectedText()
      insertPlainText(@userPrompt)
    end

    def getCommand
      c = textCursor()
      c.select(Qt::TextCursor::LineUnderCursor)

      text = c.selectedText()
      text  = text[@userPrompt.length,text.length]
      puts text
      text

    end

    def moveToEndOfLine
      moveCursor(Qt::TextCursor::EndOfLine);
    end

    def handleLeft event
      if getIndex(textCursor) > @userPrompt.length
          keyPressEvent(event, true)
      end
    end

    def handleHome
      c = textCursor
      c.movePosition(Qt::TextCursor::StartOfLine)
      c.movePosition(Qt::TextCursor::Right, Qt::TextCursor::MoveAnchor, @userPrompt.length)
      setTextCursor(c)
    end


    def getIndex crQTextCursor
      column = 1
      b = crQTextCursor.block()
      column = crQTextCursor.position - b.position
      column
    end

    def setPrompt prompt
      @userPrompt = prompt
      clearLine()
    end


  end
end